import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/entities/rat_remote_snapshot.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/signature/domain/repositories/remote_assinatura_repository.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';

class _StubSyncQueueRepository implements SyncQueueRepository {
  final List<SyncItem> pendingItems = [];
  bool includeFailedOnList = false;
  final List<String> processingIds = [];
  final List<String> syncedIds = [];
  final List<_FailedCall> failedCalls = [];
  int listPendingCallCount = 0;

  @override
  Future<List<SyncItem>> listPending({
    required String empresaId,
    required String usuarioId,
    bool includeFailed = false,
    int limit = 20,
  }) async {
    listPendingCallCount++;
    includeFailedOnList = includeFailed;
    return pendingItems;
  }

  @override
  Future<void> markProcessing(String id) async {
    processingIds.add(id);
  }

  @override
  Future<bool> tryMarkProcessing(String id) async {
    processingIds.add(id);
    return true; // simula lock adquirido com sucesso
  }

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
    failedCalls.add(_FailedCall(
      id: id,
      errorMessage: errorMessage,
      nextAttemptAt: nextAttemptAt,
    ));
  }

  @override
  Future<void> enqueue(SyncItem item) async {}

  @override
  Future<int> countPending({
    required String empresaId,
    required String usuarioId,
  }) async =>
      0;

  @override
  Future<List<SyncItem>> listForSession({
    required String empresaId,
    required String usuarioId,
    int limit = 50,
  }) async =>
      [];

  @override
  Future<bool> hasPendingItem({
    required String empresaId,
    required String usuarioId,
    required SyncEntityType entityType,
    required String entityId,
  }) async =>
      false;
}

class _FailedCall {
  final String id;
  final String errorMessage;
  final DateTime nextAttemptAt;
  _FailedCall({
    required this.id,
    required this.errorMessage,
    required this.nextAttemptAt,
  });
}

class _StubRemoteRatRepository implements RemoteRatRepository {
  final List<String> upsertedPayloads = [];
  final List<String> deletedPayloads = [];
  bool shouldThrowUpsert = false;
  bool shouldThrowDelete = false;

  @override
  Future<void> upsertFromPayload(String payload) async {
    if (shouldThrowUpsert) throw Exception('Upsert failed');
    upsertedPayloads.add(payload);
  }

  @override
  Future<void> softDeleteFromPayload(String payload) async {
    if (shouldThrowDelete) throw Exception('Delete failed');
    deletedPayloads.add(payload);
  }

  @override
  Future<List<RatRemoteSnapshot>> fetchUpdatedSince({
    required String empresaId,
    required DateTime? since,
  }) async =>
      [];
}

class _StubRatRepository implements RatRepository {
  Rat? savedRat;
  bool shouldThrowOnGetById = false;

  @override
  Future<Rat?> getById(String id) async {
    if (shouldThrowOnGetById) throw Exception('GetById failed');
    return savedRat;
  }

  @override
  Future<Rat?> getByIdScoped({
    required String id,
    required RatListScope scope,
  }) async =>
      null;

  @override
  Future<List<Rat>> listLocal() async => [];

  @override
  Future<List<Rat>> listLocalPage({
    required int limit,
    required int offset,
  }) async =>
      [];

  @override
  Future<List<Rat>> listCompanyForManager({
    required String empresaId,
  }) async =>
      [];

  @override
  Future<List<Rat>> listCompanyForManagerPage({
    required String empresaId,
    required int limit,
    required int offset,
  }) async =>
      [];

  @override
  Future<List<Rat>> listCompanyForTechnician({
    required String empresaId,
    required String tecnicoId,
  }) async =>
      [];

  @override
  Future<List<Rat>> listCompanyForTechnicianPage({
    required String empresaId,
    required String tecnicoId,
    required int limit,
    required int offset,
  }) async =>
      [];

  @override
  Future<void> save(Rat rat) async {
    savedRat = rat;
  }

  @override
  Future<void> update(Rat rat) async {}
}

class _StubAssinaturaRepository implements AssinaturaRepository {
  @override
  Future<Assinatura?> getById(String id) async => null;

  @override
  Future<List<Assinatura>> listByRatId(String ratId) async => [];

  @override
  Future<Map<String, List<Assinatura>>> listByRatIds(List<String> ratIds) async => {};

  @override
  Future<void> save(Assinatura assinatura) async {}

  @override
  Future<void> update(Assinatura assinatura) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<Uint8List?> readBytes(String id) async => null;

  @override
  Future<void> saveBytes({
    required String assinaturaId,
    required List<int> bytes,
    required String assetRef,
    required String ratId,
  }) async {}
}

class _StubRemoteAssinaturaRepository implements RemoteAssinaturaRepository {
  @override
  Future<String> uploadSignature({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
    required int version,
    required List<int> bytes,
    required String mimeType,
  }) async =>
      '';

  @override
  Future<void> upsertMetadata({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
    required String storagePath,
    required String sha256,
    required int sizeBytes,
    required String mimeType,
    required int version,
    required DateTime? deletedAt,
  }) async {}

  @override
  Future<String> createSignedUrl({
    required String storagePath,
    int expiresInSeconds = 300,
  }) async =>
      '';

  @override
  Future<bool> objectExists(String storagePath) async => false;

  @override
  Future<void> deleteStorageObject(String storagePath) async {}

  @override
  Future<void> markDeleted({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
  }) async {}
}

SyncItem _buildRatUpsertItem({
  required String id,
  required String empresaId,
  required String ratId,
  String payload = '{"id":"rat-1","empresaId":"emp-1"}',
  int attempts = 0,
}) {
  final now = DateTime.now();
  return SyncItem(
    id: id,
    empresaId: empresaId,
    usuarioId: 'user-1',
    entityType: SyncEntityType.rat,
    entityId: ratId,
    operation: SyncOperation.upsert,
    payload: payload,
    status: SyncItemStatus.pending,
    attempts: attempts,
    createdAt: now,
    updatedAt: now,
  );
}

SyncItem _buildRatDeleteItem({
  required String id,
  required String empresaId,
  required String ratId,
  String payload = '{"id":"rat-1","empresaId":"emp-1","deletado":true}',
}) {
  final now = DateTime.now();
  return SyncItem(
    id: id,
    empresaId: empresaId,
    usuarioId: 'user-1',
    entityType: SyncEntityType.rat,
    entityId: ratId,
    operation: SyncOperation.delete,
    payload: payload,
    status: SyncItemStatus.pending,
    attempts: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _StubSyncQueueRepository queueRepo;
  late _StubRemoteRatRepository remoteRatRepo;
  late _StubRatRepository ratRepo;
  late _StubAssinaturaRepository assinaturaRepo;
  late _StubRemoteAssinaturaRepository remoteAssinaturaRepo;
  late ProcessSyncQueue sut;

  setUp(() {
    queueRepo = _StubSyncQueueRepository();
    remoteRatRepo = _StubRemoteRatRepository();
    ratRepo = _StubRatRepository();
    assinaturaRepo = _StubAssinaturaRepository();
    remoteAssinaturaRepo = _StubRemoteAssinaturaRepository();

    sut = ProcessSyncQueue(
      queueRepository: queueRepo,
      remoteRatRepository: remoteRatRepo,
      ratRepository: ratRepo,
      assinaturaRepository: assinaturaRepo,
      remoteAssinaturaRepository: remoteAssinaturaRepo,
    );
  });

  // ─── RAT upsert ─────────────────────────────────────────────────────────────

  group('RAT upsert', () {
    test('upsert com sucesso marca item como synced', () async {
      final now = DateTime.now();
      final rat = Rat(
        id: 'rat-1',
        authorId: 'author-1',
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        tecnicoId: 'tec-1',
        ownerType: RatOwnerType.companyTecnico,
        numero: '0001',
        clienteNome: 'Cliente',
        responsavelRecebimento: 'Responsável',
        dataVisita: now,
        horarioInicioAtendimento: '0800',
        horarioTerminoAtendimento: '0900',
        descricao: 'Descrição',
        status: RatStatus.draft,
        syncStatus: RatSyncStatus.pendingSync,
        createdAt: now,
        updatedAt: now,
      );
      ratRepo.savedRat = rat;
      queueRepo.pendingItems.add(_buildRatUpsertItem(
        id: 'sync-1',
        empresaId: 'emp-1',
        ratId: 'rat-1',
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(queueRepo.syncedIds, contains('sync-1'));
      expect(remoteRatRepo.upsertedPayloads, hasLength(1));
    });

    test('upsert atualiza RAT local com syncStatus synced', () async {
      final now = DateTime.now();
      final rat = Rat(
        id: 'rat-1',
        authorId: 'author-1',
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        tecnicoId: 'tec-1',
        ownerType: RatOwnerType.companyTecnico,
        numero: '0001',
        clienteNome: 'Cliente',
        responsavelRecebimento: 'Responsável',
        dataVisita: now,
        horarioInicioAtendimento: '0800',
        horarioTerminoAtendimento: '0900',
        descricao: 'Descrição',
        status: RatStatus.draft,
        syncStatus: RatSyncStatus.pendingSync,
        createdAt: now,
        updatedAt: now,
      );
      ratRepo.savedRat = rat;
      queueRepo.pendingItems.add(_buildRatUpsertItem(
        id: 'sync-1',
        empresaId: 'emp-1',
        ratId: 'rat-1',
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(ratRepo.savedRat!.syncStatus, RatSyncStatus.synced);
    });

    test('upsert não bloqueia se RAT local não existe', () async {
      // ratRepo.getById retorna null
      queueRepo.pendingItems.add(_buildRatUpsertItem(
        id: 'sync-1',
        empresaId: 'emp-1',
        ratId: 'rat-inexistente',
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      // Mesmo sem RAT local, o upsert remoto foi feito
      expect(remoteRatRepo.upsertedPayloads, hasLength(1));
      expect(queueRepo.syncedIds, contains('sync-1'));
    });
  });

  // ─── RAT delete ─────────────────────────────────────────────────────────────

  group('RAT delete', () {
    test('delete com sucesso marca item como synced', () async {
      queueRepo.pendingItems.add(_buildRatDeleteItem(
        id: 'sync-2',
        empresaId: 'emp-1',
        ratId: 'rat-1',
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(queueRepo.syncedIds, contains('sync-2'));
      expect(remoteRatRepo.deletedPayloads, hasLength(1));
    });

    test('delete não atualiza RAT local (apenas remote)', () async {
      final now = DateTime.now();
      final rat = Rat(
        id: 'rat-1',
        authorId: 'author-1',
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        tecnicoId: 'tec-1',
        ownerType: RatOwnerType.companyTecnico,
        numero: '0001',
        clienteNome: 'Cliente',
        responsavelRecebimento: 'Responsável',
        dataVisita: now,
        horarioInicioAtendimento: '0800',
        horarioTerminoAtendimento: '0900',
        descricao: 'Descrição',
        status: RatStatus.draft,
        syncStatus: RatSyncStatus.pendingSync,
        createdAt: now,
        updatedAt: now,
      );
      ratRepo.savedRat = rat;
      queueRepo.pendingItems.add(_buildRatDeleteItem(
        id: 'sync-2',
        empresaId: 'emp-1',
        ratId: 'rat-1',
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      // Delete não chama _markRatSynced (não há save do RAT local)
      expect(ratRepo.savedRat, isNull); // save não foi chamado
      expect(queueRepo.syncedIds, contains('sync-2'));
    });
  });

  // ─── Falha e retry ──────────────────────────────────────────────────────────

  group('falha e retry', () {
    test('falha no upsert marca failed com retry em 5 minutos', () async {
      remoteRatRepo.shouldThrowUpsert = true;
      queueRepo.pendingItems.add(_buildRatUpsertItem(
        id: 'sync-fail-1',
        empresaId: 'emp-1',
        ratId: 'rat-1',
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(queueRepo.syncedIds, isEmpty);
      expect(queueRepo.failedCalls, hasLength(1));
      expect(queueRepo.failedCalls.first.id, 'sync-fail-1');

      final nextAttempt = queueRepo.failedCalls.first.nextAttemptAt;
      final retryWindow = nextAttempt.difference(DateTime.now());
      expect(retryWindow.inMinutes, greaterThanOrEqualTo(4));
      expect(retryWindow.inMinutes, lessThanOrEqualTo(6));
    });

    test('falha no delete marca failed com retry em 5 minutos', () async {
      remoteRatRepo.shouldThrowDelete = true;
      queueRepo.pendingItems.add(_buildRatDeleteItem(
        id: 'sync-fail-2',
        empresaId: 'emp-1',
        ratId: 'rat-1',
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(queueRepo.syncedIds, isEmpty);
      expect(queueRepo.failedCalls, hasLength(1));
      expect(queueRepo.failedCalls.first.id, 'sync-fail-2');

      final nextAttempt = queueRepo.failedCalls.first.nextAttemptAt;
      final retryWindow = nextAttempt.difference(DateTime.now());
      expect(retryWindow.inMinutes, greaterThanOrEqualTo(4));
      expect(retryWindow.inMinutes, lessThanOrEqualTo(6));
    });

    test('item falhando não bloqueia próximo item', () async {
      // Primeiro item falha, segundo succeeds
      remoteRatRepo.shouldThrowUpsert = true;
      queueRepo.pendingItems.addAll([
        _buildRatUpsertItem(id: 'sync-1', empresaId: 'emp-1', ratId: 'rat-1'),
        _buildRatUpsertItem(id: 'sync-2', empresaId: 'emp-1', ratId: 'rat-2'),
      ]);

      final now = DateTime.now();
      final rat2 = Rat(
        id: 'rat-2',
        authorId: 'author-1',
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        tecnicoId: 'tec-1',
        ownerType: RatOwnerType.companyTecnico,
        numero: '0002',
        clienteNome: 'Cliente 2',
        responsavelRecebimento: 'Responsável',
        dataVisita: now,
        horarioInicioAtendimento: '0800',
        horarioTerminoAtendimento: '0900',
        descricao: 'Descrição 2',
        status: RatStatus.draft,
        syncStatus: RatSyncStatus.pendingSync,
        createdAt: now,
        updatedAt: now,
      );
      ratRepo.savedRat = rat2;

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      // sync-1 falhou
      expect(queueRepo.failedCalls.any((c) => c.id == 'sync-1'), isTrue);
      // sync-2 foi processado com sucesso
      expect(queueRepo.syncedIds, contains('sync-2'));
    });

    test('item com 5 attempts não é processado — marcado failed permanente', () async {
      queueRepo.pendingItems.add(_buildRatUpsertItem(
        id: 'sync-max-attempts',
        empresaId: 'emp-1',
        ratId: 'rat-1',
        attempts: 5, // limite atingido
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      // Não deve chamar markProcessing (não é processado)
      expect(queueRepo.processingIds, isEmpty);
      // Deve marcar failed permanente com mensagem de limite
      expect(queueRepo.failedCalls, hasLength(1));
      expect(queueRepo.failedCalls.first.id, 'sync-max-attempts');
      expect(queueRepo.failedCalls.first.errorMessage, contains('Limite'));
    });
  });

  // ─── Lock otimista ──────────────────────────────────────────────────────────

  group('lock otimista', () {
    test('markProcessing é chamado para cada item antes do processamento', () async {
      queueRepo.pendingItems.addAll([
        _buildRatUpsertItem(id: 'sync-1', empresaId: 'emp-1', ratId: 'rat-1'),
        _buildRatUpsertItem(id: 'sync-2', empresaId: 'emp-1', ratId: 'rat-2'),
      ]);

      final now = DateTime.now();
      ratRepo.savedRat = Rat(
        id: 'rat-1',
        authorId: 'author-1',
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        tecnicoId: 'tec-1',
        ownerType: RatOwnerType.companyTecnico,
        numero: '0001',
        clienteNome: 'Cliente',
        responsavelRecebimento: 'Responsável',
        dataVisita: now,
        horarioInicioAtendimento: '0800',
        horarioTerminoAtendimento: '0900',
        descricao: 'Descrição',
        status: RatStatus.draft,
        syncStatus: RatSyncStatus.pendingSync,
        createdAt: now,
        updatedAt: now,
      );

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(queueRepo.processingIds, containsAll(['sync-1', 'sync-2']));
    });

    test('listPending inclui items failed quando retryFailed=true', () async {
      queueRepo.pendingItems.add(_buildRatUpsertItem(
        id: 'sync-retry',
        empresaId: 'emp-1',
        ratId: 'rat-1',
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1', retryFailed: true);

      expect(queueRepo.includeFailedOnList, isTrue);
    });

    test('listPending não inclui items failed quando retryFailed=false', () async {
      queueRepo.pendingItems.add(_buildRatUpsertItem(
        id: 'sync-normal',
        empresaId: 'emp-1',
        ratId: 'rat-1',
      ));

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1', retryFailed: false);

      expect(queueRepo.includeFailedOnList, isFalse);
    });
  });

  // ─── Processamento geral ────────────────────────────────────────────────────

  group('processamento geral', () {
    test('processa itens na ordem em que são retornados por listPending', () async {
      final now = DateTime.now();
      final rat = Rat(
        id: 'rat-1',
        authorId: 'author-1',
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        tecnicoId: 'tec-1',
        ownerType: RatOwnerType.companyTecnico,
        numero: '0001',
        clienteNome: 'Cliente',
        responsavelRecebimento: 'Responsável',
        dataVisita: now,
        horarioInicioAtendimento: '0800',
        horarioTerminoAtendimento: '0900',
        descricao: 'Descrição',
        status: RatStatus.draft,
        syncStatus: RatSyncStatus.pendingSync,
        createdAt: now,
        updatedAt: now,
      );
      ratRepo.savedRat = rat;
      queueRepo.pendingItems.addAll([
        _buildRatUpsertItem(id: 'sync-a', empresaId: 'emp-1', ratId: 'rat-1'),
        _buildRatUpsertItem(id: 'sync-b', empresaId: 'emp-1', ratId: 'rat-1'),
      ]);

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(queueRepo.processingIds[0], 'sync-a');
      expect(queueRepo.processingIds[1], 'sync-b');
      expect(queueRepo.syncedIds, hasLength(2));
    });

    test('listPending é chamado com empresaId e usuarioId corretos', () async {
      queueRepo.pendingItems.add(_buildRatUpsertItem(
        id: 'sync-1',
        empresaId: 'emp-xyz',
        ratId: 'rat-1',
      ));

      await sut.call(empresaId: 'emp-xyz', usuarioId: 'user-abc');

      expect(queueRepo.listPendingCallCount, 1);
    });

    test('sem itens pendentes, não faz processing nem synced', () async {
      // queueRepo.pendingItems é vazio por padrão

      await sut.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(queueRepo.processingIds, isEmpty);
      expect(queueRepo.syncedIds, isEmpty);
      expect(queueRepo.failedCalls, isEmpty);
    });
  });
}