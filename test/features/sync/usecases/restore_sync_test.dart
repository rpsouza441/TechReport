import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/data/repositories/supabase_remote_rat_repository.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/entities/rat_remote_snapshot.dart';
import 'package:techreport/features/rat/domain/permissions/rat_permissions.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/restore_rat.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/signature/domain/repositories/remote_assinatura_repository.dart';
import 'package:techreport/features/sync/data/repositories/drift_sync_queue_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/entities/sync_session_context.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';
import 'package:techreport/shared/infra/database/tech_report_local_database.dart'
    hide Assinatura, Rat;

void main() {
  group('RestoreRat local estreito', () {
    test('modo local altera somente deletedAt e syncStatus', () async {
      final before = _deletedRat(ownerType: RatOwnerType.localTecnico);
      final repository = _RecordingRatRepository(before);
      final restore = RestoreRat(
        ratRepository: repository,
        permissions: const RatPermissions(),
      );

      final after = await restore(ratId: before.id, session: null);

      expect(after.deletedAt, isNull);
      expect(after.syncStatus, RatSyncStatus.localOnly);
      _expectSnapshotPreserved(before, after);
      expect(repository.restoreCalls, [(before.id, RatSyncStatus.localOnly)]);
      expect(repository.saveCalls, 0);
      expect(repository.updateCalls, 0);
    });

    test('modo empresa preserva snapshot e marca pendingSync', () async {
      final before = _deletedRat();
      final repository = _RecordingRatRepository(before);
      final restore = RestoreRat(
        ratRepository: repository,
        permissions: const RatPermissions(),
      );

      final after = await restore(ratId: before.id, session: _session());

      expect(after.deletedAt, isNull);
      expect(after.syncStatus, RatSyncStatus.pendingSync);
      _expectSnapshotPreserved(before, after);
      expect(repository.restoreCalls, [(before.id, RatSyncStatus.pendingSync)]);
      expect(repository.saveCalls, 0);
      expect(repository.updateCalls, 0);
    });

    test(
      'cross-company e app_admin falham antes de qualquer escrita',
      () async {
        for (final session in [
          _session(empresaId: 'outra-empresa'),
          _appAdminSession(),
        ]) {
          final repository = _RecordingRatRepository(_deletedRat());
          final restore = RestoreRat(
            ratRepository: repository,
            permissions: const RatPermissions(),
          );

          expect(
            () => restore(ratId: 'rat-1', session: session),
            throwsA(isA<RestoreRatAccessDeniedException>()),
          );
          expect(repository.restoreCalls, isEmpty);
          expect(repository.saveCalls, 0);
          expect(repository.updateCalls, 0);
        }
      },
    );

    test('RAT ausente tem falha tipada e nao escreve', () async {
      final repository = _RecordingRatRepository(null);
      final restore = RestoreRat(
        ratRepository: repository,
        permissions: const RatPermissions(),
      );

      expect(
        () => restore(ratId: 'rat-ausente', session: null),
        throwsA(isA<RestoreRatNotFoundException>()),
      );
      expect(repository.restoreCalls, isEmpty);
    });
  });

  group('restore remoto estreito', () {
    test('envia somente id no filtro e deletado=false no PATCH', () async {
      final httpClient = _RecordingHttpClient(responseBody: '[{"id":"rat-1"}]');
      final repository = _remoteRepository(httpClient);
      final staleSnapshot = {
        'id': 'rat-1',
        'status': 'draft',
        'tecnico_id': 'tecnico-antigo',
        'empresa_id': 'empresa-1',
        'descricao': 'snapshot desatualizado',
        'assinatura': 'nao reenviar',
        'deletado': true,
      };

      await repository.restoreFromPayload(jsonEncode(staleSnapshot));

      expect(httpClient.requests, hasLength(1));
      final request = httpClient.requests.single;
      expect(request.method, 'PATCH');
      expect(request.url.path, endsWith('/rest/v1/rats'));
      expect(request.url.queryParameters['id'], 'eq.rat-1');
      expect(jsonDecode(request.body), {'deletado': false});
      expect(request.body, isNot(contains('status')));
      expect(request.body, isNot(contains('descricao')));
      expect(request.body, isNot(contains('assinatura')));
      expect(request.body, isNot(contains('tecnico_id')));
      expect(request.body, isNot(contains('empresa_id')));
    });

    test('zero linhas retornadas nao e tratado como sucesso', () async {
      final repository = _remoteRepository(
        _RecordingHttpClient(responseBody: '[]'),
      );

      expect(
        repository.restoreFromPayload('{"id":"rat-negada"}'),
        throwsA(anything),
      );
    });
  });

  group('fila latest-wins', () {
    late TechReportLocalDatabase database;
    late DriftSyncQueueRepository queue;

    setUp(() {
      database = TechReportLocalDatabase(NativeDatabase.memory());
      queue = DriftSyncQueueRepository(database);
    });

    tearDown(() => database.close());

    for (final previousOperation in [
      SyncOperation.delete,
      SyncOperation.upsert,
    ]) {
      test('$previousOperation -> restore substitui payload stale', () async {
        await queue.enqueue(
          _syncItem(
            operation: previousOperation,
            payload: '{"id":"rat-1","descricao":"stale"}',
          ),
        );
        final enqueue = EnqueueRatSync(queueRepository: queue);

        await enqueue.restore(_deletedRat(), session: _syncSession());

        final item = (await queue.listForSession(
          empresaId: 'empresa-1',
          usuarioId: 'usuario-atual',
        )).single;
        expect(item.operation, SyncOperation.restore);
        expect(jsonDecode(item.payload), {'id': 'rat-1'});
        expect(item.payload, isNot(contains('descricao')));
        expect(item.payload, isNot(contains('status')));
        expect(item.payload, isNot(contains('tecnico')));
      });
    }

    test('failed -> restore limpa tentativas, erro e agendamento', () async {
      await queue.enqueue(
        _syncItem(
          operation: SyncOperation.delete,
          status: SyncItemStatus.failed,
          attempts: 4,
          lastError: 'timeout',
          nextAttemptAt: DateTime(2026, 8, 10),
        ),
      );
      final enqueue = EnqueueRatSync(queueRepository: queue);

      await enqueue.restore(_deletedRat(), session: _syncSession());

      final item = (await queue.listForSession(
        empresaId: 'empresa-1',
        usuarioId: 'usuario-atual',
      )).single;
      expect(item.operation, SyncOperation.restore);
      expect(item.status, SyncItemStatus.pending);
      expect(item.attempts, 0);
      expect(item.lastError, isNull);
      expect(item.nextAttemptAt, isNull);
    });

    test(
      'sessao invalida/app_admin sem empresa ou empresa divergente nao toca fila',
      () async {
        final enqueue = EnqueueRatSync(queueRepository: queue);
        final cases = [
          const SyncSessionContext(empresaId: '', usuarioId: ''),
          const SyncSessionContext(
            empresaId: 'outra-empresa',
            usuarioId: 'usuario-1',
          ),
        ];

        for (final session in cases) {
          await expectLater(
            enqueue.restore(_deletedRat(), session: session),
            throwsA(anything),
          );
        }
        expect(
          await queue.listForSession(
            empresaId: 'empresa-1',
            usuarioId: 'usuario-atual',
          ),
          isEmpty,
        );
      },
    );
  });

  group('processamento de restore', () {
    test(
      'sucesso remoto precede sync local e nunca envia upsert/delete',
      () async {
        final order = <String>[];
        final queue = _ProcessingQueue(_restoreItem(), order);
        final remote = _RecordingRemoteRatRepository(order: order);
        final local = _RecordingRatRepository(
          _deletedRat().copyWith(
            deletedAt: null,
            syncStatus: RatSyncStatus.pendingSync,
          ),
          order: order,
        );
        final processor = _processor(
          queue: queue,
          remote: remote,
          local: local,
        );

        await processor.call(
          empresaId: 'empresa-1',
          usuarioId: 'usuario-atual',
        );

        expect(remote.restoredPayloads, ['{"id":"rat-1"}']);
        expect(remote.upsertedPayloads, isEmpty);
        expect(remote.deletedPayloads, isEmpty);
        expect(local.saved!.deletedAt, isNull);
        expect(local.saved!.syncStatus, RatSyncStatus.synced);
        expect(
          order.indexOf('remote-restore'),
          lessThan(order.indexOf('local-save')),
        );
        expect(queue.syncedIds, ['sync-1']);
        expect(queue.failedIds, isEmpty);
      },
    );

    test(
      'falha remota mantem restore local pendente e item retryable',
      () async {
        final queue = _ProcessingQueue(_restoreItem(), []);
        final remote = _RecordingRemoteRatRepository()..failRestore = true;
        final local = _RecordingRatRepository(
          _deletedRat().copyWith(
            deletedAt: null,
            syncStatus: RatSyncStatus.pendingSync,
          ),
        );
        final processor = _processor(
          queue: queue,
          remote: remote,
          local: local,
        );

        await processor.call(
          empresaId: 'empresa-1',
          usuarioId: 'usuario-atual',
        );

        expect(local.rat!.deletedAt, isNull);
        expect(local.rat!.syncStatus, RatSyncStatus.pendingSync);
        expect(local.saveCalls, 0);
        expect(queue.syncedIds, isEmpty);
        expect(queue.failedIds, ['sync-1']);
      },
    );
  });
}

ProcessSyncQueue _processor({
  required SyncQueueRepository queue,
  required RemoteRatRepository remote,
  required RatRepository local,
}) {
  return ProcessSyncQueue(
    queueRepository: queue,
    remoteRatRepository: remote,
    ratRepository: local,
    assinaturaRepository: _FakeAssinaturaRepository(),
    remoteAssinaturaRepository: _FakeRemoteAssinaturaRepository(),
  );
}

SupabaseRemoteRatRepository _remoteRepository(_RecordingHttpClient httpClient) {
  return SupabaseRemoteRatRepository(
    clientFactory: _FakeSupabaseClientFactory(
      SupabaseClient(
        'https://project.supabase.co',
        'public-anon-key',
        httpClient: httpClient,
      ),
    ),
  );
}

void _expectSnapshotPreserved(Rat before, Rat after) {
  expect(after.id, before.id);
  expect(after.authorId, before.authorId);
  expect(after.empresaId, before.empresaId);
  expect(after.usuarioId, before.usuarioId);
  expect(after.tecnicoId, before.tecnicoId);
  expect(after.ownerType, before.ownerType);
  expect(after.numero, before.numero);
  expect(after.clienteNome, before.clienteNome);
  expect(after.responsavelRecebimento, before.responsavelRecebimento);
  expect(after.responsavelDocumento, before.responsavelDocumento);
  expect(after.dataVisita, before.dataVisita);
  expect(after.horarioInicioAtendimento, before.horarioInicioAtendimento);
  expect(after.horarioTerminoAtendimento, before.horarioTerminoAtendimento);
  expect(after.descricao, before.descricao);
  expect(after.equipamentoMovimentoTipo, before.equipamentoMovimentoTipo);
  expect(after.equipamentoDescricao, before.equipamentoDescricao);
  expect(after.equipamentoObservacao, before.equipamentoObservacao);
  expect(after.status, before.status);
  expect(after.createdAt, before.createdAt);
  expect(after.updatedAt, before.updatedAt);
  expect(after.ultimoAlteradorUserId, before.ultimoAlteradorUserId);
  expect(after.ultimaAlteracaoEm, before.ultimaAlteracaoEm);
  expect(after.reabertaParaCorrecaoEm, before.reabertaParaCorrecaoEm);
  expect(
    after.reabertaParaCorrecaoPorUserId,
    before.reabertaParaCorrecaoPorUserId,
  );
  expect(after.motivoReabertura, before.motivoReabertura);
  expect(after.assinaturaInvalidadaEm, before.assinaturaInvalidadaEm);
  expect(
    after.assinaturaInvalidadaPorUserId,
    before.assinaturaInvalidadaPorUserId,
  );
}

class _RecordingRatRepository implements RatRepository {
  _RecordingRatRepository(this.rat, {this.order});

  Rat? rat;
  Rat? saved;
  final List<String>? order;
  final List<(String, RatSyncStatus)> restoreCalls = [];
  int saveCalls = 0;
  int updateCalls = 0;

  @override
  Future<Rat?> getById(String id) async => rat;

  @override
  Future<void> restore({
    required String id,
    required RatSyncStatus syncStatus,
  }) async {
    restoreCalls.add((id, syncStatus));
    rat = rat?.copyWith(deletedAt: null, syncStatus: syncStatus);
  }

  @override
  Future<void> save(Rat rat) async {
    saveCalls++;
    order?.add('local-save');
    saved = rat;
    this.rat = rat;
  }

  @override
  Future<void> update(Rat rat) async {
    updateCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingRemoteRatRepository implements RemoteRatRepository {
  _RecordingRemoteRatRepository({this.order});

  final List<String>? order;
  final List<String> restoredPayloads = [];
  final List<String> upsertedPayloads = [];
  final List<String> deletedPayloads = [];
  bool failRestore = false;

  @override
  Future<void> restoreFromPayload(String payload) async {
    if (failRestore) throw const SocketException('sem conexao');
    order?.add('remote-restore');
    restoredPayloads.add(payload);
  }

  @override
  Future<void> upsertFromPayload(String payload) async {
    upsertedPayloads.add(payload);
  }

  @override
  Future<void> softDeleteFromPayload(String payload) async {
    deletedPayloads.add(payload);
  }

  @override
  Future<List<RatRemoteSnapshot>> fetchUpdatedSince({
    required String empresaId,
    required DateTime? since,
  }) async => [];
}

class _ProcessingQueue implements SyncQueueRepository {
  _ProcessingQueue(this.item, this.order);

  final SyncItem item;
  final List<String> order;
  final List<String> syncedIds = [];
  final List<String> failedIds = [];

  @override
  Future<List<SyncItem>> listPending({
    required String empresaId,
    required String usuarioId,
    bool includeFailed = false,
    int limit = 20,
  }) async => [item];

  @override
  Future<bool> tryMarkProcessing(String id) async => true;

  @override
  Future<void> markSynced(String id) async {
    syncedIds.add(id);
  }

  @override
  Future<void> markFailed({
    required String id,
    required String errorMessage,
    required DateTime nextAttemptAt,
  }) async {
    failedIds.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAssinaturaRepository implements AssinaturaRepository {
  @override
  Future<Assinatura?> getById(String id) async => null;

  @override
  Future<List<Assinatura>> listByRatId(String ratId) async => [];

  @override
  Future<Map<String, List<Assinatura>>> listByRatIds(
    List<String> ratIds,
  ) async => {};

  @override
  Future<Uint8List?> readBytes(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemoteAssinaturaRepository implements RemoteAssinaturaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSupabaseClientFactory implements SupabaseClientFactory {
  _FakeSupabaseClientFactory(this.client);

  final SupabaseClient client;

  @override
  Future<SupabaseClient?> tryCreateAuthenticatedClient() async => client;

  @override
  Future<SupabaseClient?> tryCreateClient() async => client;
}

class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.url,
    required this.body,
  });

  final String method;
  final Uri url;
  final String body;
}

class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient({required this.responseBody, this.statusCode = 200});

  final String responseBody;
  final int statusCode;
  final List<_RecordedRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().bytesToString();
    requests.add(
      _RecordedRequest(method: request.method, url: request.url, body: body),
    );
    return http.StreamedResponse(
      Stream.value(utf8.encode(responseBody)),
      statusCode,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }
}

Rat _deletedRat({RatOwnerType ownerType = RatOwnerType.companyTecnico}) {
  final createdAt = DateTime.parse('2026-08-01T10:00:00Z');
  return Rat(
    id: 'rat-1',
    authorId: 'author-1',
    empresaId: ownerType == RatOwnerType.localTecnico ? null : 'empresa-1',
    usuarioId: ownerType == RatOwnerType.localTecnico ? null : 'criador-1',
    tecnicoId: ownerType == RatOwnerType.localTecnico ? null : 'tecnico-1',
    ownerType: ownerType,
    numero: 'RAT-001',
    clienteNome: 'Cliente preservado',
    responsavelRecebimento: 'Responsável',
    responsavelDocumento: '123.456.789-00',
    dataVisita: DateTime.parse('2026-08-02T10:00:00Z'),
    horarioInicioAtendimento: '08:00',
    horarioTerminoAtendimento: '09:30',
    descricao: 'Descrição preservada',
    equipamentoMovimentoTipo: EquipamentoMovimentoTipo.retiradaParaReparo,
    equipamentoDescricao: 'Equipamento',
    equipamentoObservacao: 'Observação',
    status: RatStatus.finalizado,
    syncStatus: RatSyncStatus.synced,
    createdAt: createdAt,
    updatedAt: DateTime.parse('2026-08-08T10:00:00Z'),
    deletedAt: DateTime.parse('2026-08-09T10:00:00Z'),
    ultimoAlteradorUserId: 'gerente-1',
    ultimaAlteracaoEm: DateTime.parse('2026-08-08T10:00:00Z'),
    reabertaParaCorrecaoEm: DateTime.parse('2026-08-07T10:00:00Z'),
    reabertaParaCorrecaoPorUserId: 'gerente-1',
    motivoReabertura: 'Correção autorizada',
    assinaturaInvalidadaEm: DateTime.parse('2026-08-07T10:00:00Z'),
    assinaturaInvalidadaPorUserId: 'gerente-1',
  );
}

SyncItem _syncItem({
  required SyncOperation operation,
  String payload = '{"id":"rat-1"}',
  SyncItemStatus status = SyncItemStatus.pending,
  int attempts = 0,
  String? lastError,
  DateTime? nextAttemptAt,
}) {
  final now = DateTime(2026, 8, 9, 10);
  return SyncItem(
    id: 'sync-1',
    empresaId: 'empresa-1',
    usuarioId: 'usuario-anterior',
    entityType: SyncEntityType.rat,
    entityId: 'rat-1',
    operation: operation,
    payload: payload,
    status: status,
    attempts: attempts,
    lastError: lastError,
    nextAttemptAt: nextAttemptAt,
    createdAt: now,
    updatedAt: now,
  );
}

SyncItem _restoreItem() =>
    _syncItem(operation: SyncOperation.restore, payload: '{"id":"rat-1"}');

SyncSessionContext _syncSession() => const SyncSessionContext(
  empresaId: 'empresa-1',
  usuarioId: 'usuario-atual',
);

SessaoRemota _session({String empresaId = 'empresa-1'}) {
  final now = DateTime.now();
  return SessaoRemota(
    id: 'session-1',
    empresaId: empresaId,
    usuarioId: 'usuario-1',
    tecnicoId: 'tecnico-1',
    email: 'user@example.com',
    nome: 'Usuário',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: SessaoRemotaPapelEmpresa.tecnico,
    accessTokenRef: 'access-token',
    refreshTokenRef: 'refresh-token',
    endpointRef: 'endpoint',
    expiresAt: now.add(const Duration(hours: 1)),
    lastValidatedAt: now,
    offlineAccessUntil: now.add(const Duration(days: 7)),
    createdAt: now,
    updatedAt: now,
  );
}

SessaoRemota _appAdminSession() {
  final now = DateTime.now();
  return SessaoRemota(
    id: 'session-app-admin',
    empresaId: null,
    usuarioId: 'app-admin-1',
    tecnicoId: null,
    email: 'admin@example.com',
    nome: 'Admin global',
    mustChangePassword: false,
    papelGlobal: SessaoRemotaPapelGlobal.appAdmin,
    papelEmpresa: null,
    accessTokenRef: 'access-token',
    refreshTokenRef: 'refresh-token',
    endpointRef: 'endpoint',
    expiresAt: now.add(const Duration(hours: 1)),
    lastValidatedAt: now,
    offlineAccessUntil: now.add(const Duration(days: 7)),
    createdAt: now,
    updatedAt: now,
  );
}
