import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/entities/sync_session_context.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';

/// Stub que espelha a semantica cross-user/cross-operation do
/// [DriftSyncQueueRepository.replacePendingPayload]: no maximo um item
/// pendente/falho por (empresaId, entityType, entityId); ao substituir,
/// transfere o escopo (`usuarioId`) e a `operation`.
class _StubSyncQueueRepository implements SyncQueueRepository {
  final List<SyncItem> enqueued = [];
  final List<_ReplaceCall> replaceCalls = [];
  final List<SyncItem> existingItems = [];
  bool hasPendingItemReturn = false;

  @override
  Future<bool> replacePendingPayload({
    required String empresaId,
    required String usuarioId,
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required String payload,
    required DateTime updatedAt,
    bool resetFailure = true,
  }) async {
    replaceCalls.add(
      _ReplaceCall(
        empresaId: empresaId,
        usuarioId: usuarioId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
        updatedAt: updatedAt,
        resetFailure: resetFailure,
      ),
    );

    final index = existingItems.indexWhere((item) {
      final statusMatches =
          item.status == SyncItemStatus.pending ||
          (resetFailure && item.status == SyncItemStatus.failed);
      return item.empresaId == empresaId &&
          item.entityType == entityType &&
          item.entityId == entityId &&
          statusMatches;
    });

    if (index < 0) return false;

    final item = existingItems[index];
    final resetFailed = resetFailure && item.status == SyncItemStatus.failed;
    existingItems[index] = SyncItem(
      id: item.id,
      empresaId: item.empresaId,
      usuarioId: usuarioId,
      entityType: item.entityType,
      entityId: item.entityId,
      operation: operation,
      payload: payload,
      status: resetFailed ? SyncItemStatus.pending : item.status,
      attempts: resetFailed ? 0 : item.attempts,
      lastError: resetFailed ? null : item.lastError,
      nextAttemptAt: resetFailed ? null : item.nextAttemptAt,
      createdAt: item.createdAt,
      updatedAt: updatedAt,
    );
    return true;
  }

  @override
  Future<bool> hasPendingItem({
    required String empresaId,
    required String usuarioId,
    required SyncEntityType entityType,
    required String entityId,
  }) async => hasPendingItemReturn;

  @override
  Future<void> enqueue(SyncItem item) async {
    enqueued.add(item);
  }

  @override
  Future<List<SyncItem>> listPending({
    required String empresaId,
    required String usuarioId,
    bool includeFailed = false,
    int limit = 20,
  }) async => [];

  @override
  Future<int> countPending({
    required String empresaId,
    required String usuarioId,
  }) async => 0;

  @override
  Future<void> markProcessing(String id) async {}

  @override
  Future<bool> tryMarkProcessing(String id) async => true;

  @override
  Future<void> markSynced(String id) async {}

  @override
  Future<void> markFailed({
    required String id,
    required String errorMessage,
    required DateTime nextAttemptAt,
  }) async {}

  @override
  Future<List<SyncItem>> listForSession({
    required String empresaId,
    required String usuarioId,
    int limit = 50,
  }) async => [];
}

class _ReplaceCall {
  const _ReplaceCall({
    required this.empresaId,
    required this.usuarioId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.updatedAt,
    required this.resetFailure,
  });

  final String empresaId;
  final String usuarioId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final String payload;
  final DateTime updatedAt;
  final bool resetFailure;
}

const _session = SyncSessionContext(empresaId: 'emp-1', usuarioId: 'user-1');

void main() {
  late _StubSyncQueueRepository queueRepo;
  late EnqueueRatSync sut;

  setUp(() {
    queueRepo = _StubSyncQueueRepository();
    sut = EnqueueRatSync(queueRepository: queueRepo);
  });

  group('upsert', () {
    test('cria item no escopo da sessao quando nao ha pendencia', () async {
      final rat = _makeRat(id: 'rat-1');

      await sut.upsert(rat, session: _session);

      expect(queueRepo.replaceCalls, hasLength(1));
      expect(queueRepo.enqueued, hasLength(1));
      final item = queueRepo.enqueued.first;
      expect(item.entityType, SyncEntityType.rat);
      expect(item.operation, SyncOperation.upsert);
      expect(item.entityId, 'rat-1');
      expect(item.empresaId, 'emp-1');
      expect(item.usuarioId, 'user-1');
    });

    test('payload preserva criado_por_user_id do criador', () async {
      // RAT criada por outro tecnico (criador), editada pela sessao user-1.
      final rat = _makeRat(id: 'rat-1', usuarioId: 'criador-99');

      await sut.upsert(rat, session: _session);

      final payload =
          jsonDecode(queueRepo.enqueued.single.payload) as Map<String, dynamic>;
      expect(payload['criado_por_user_id'], 'criador-99');
      // Mas o escopo da fila e o da sessao.
      expect(queueRepo.enqueued.single.usuarioId, 'user-1');
    });

    test('atualiza payload existente e nao cria duplicado', () async {
      queueRepo.existingItems.add(
        _syncItem(payload: jsonEncode({'id': 'rat-1', 'descricao': 'antiga'})),
      );

      await sut.upsert(
        _makeRat(
          id: 'rat-1',
          descricao: 'nova',
          motivoReabertura: 'Corrigir valores',
        ),
        session: _session,
      );

      expect(queueRepo.enqueued, isEmpty);
      expect(queueRepo.existingItems, hasLength(1));
      final payload =
          jsonDecode(queueRepo.existingItems.single.payload)
              as Map<String, dynamic>;
      expect(payload['descricao'], 'nova');
      expect(payload['motivo_reabertura'], 'Corrigir valores');
    });

    test('edicao por outro usuario assume o item (RF-09)', () async {
      // Item pendente do usuario A.
      queueRepo.existingItems.add(_syncItem(usuarioId: 'user-A'));

      // Usuario B (sessao) salva a mesma RAT.
      const sessionB = SyncSessionContext(
        empresaId: 'emp-1',
        usuarioId: 'user-B',
      );
      await sut.upsert(
        _makeRat(id: 'rat-1', descricao: 'nova'),
        session: sessionB,
      );

      expect(queueRepo.enqueued, isEmpty);
      expect(queueRepo.existingItems, hasLength(1));
      expect(queueRepo.existingItems.single.usuarioId, 'user-B');
    });

    test('renova item failed para pending com payload novo', () async {
      queueRepo.existingItems.add(
        _syncItem(
          status: SyncItemStatus.failed,
          attempts: 2,
          lastError: 'timeout',
          nextAttemptAt: DateTime(2026, 6, 26, 11),
        ),
      );

      await sut.upsert(
        _makeRat(id: 'rat-1', motivoReabertura: 'Nova tentativa'),
        session: _session,
      );

      expect(queueRepo.enqueued, isEmpty);
      final item = queueRepo.existingItems.single;
      expect(item.status, SyncItemStatus.pending);
      expect(item.attempts, 0);
    });

    test('nao sobrescreve processing e cria novo pending', () async {
      queueRepo.existingItems.add(_syncItem(status: SyncItemStatus.processing));

      await sut.upsert(
        _makeRat(id: 'rat-1', descricao: 'nova'),
        session: _session,
      );

      expect(queueRepo.existingItems.first.status, SyncItemStatus.processing);
      expect(queueRepo.enqueued, hasLength(1));
      expect(queueRepo.enqueued.first.operation, SyncOperation.upsert);
    });

    test('upsert posterior substitui pending delete (RF-09)', () async {
      queueRepo.existingItems.add(_syncItem(operation: SyncOperation.delete));

      await sut.upsert(
        _makeRat(id: 'rat-1', descricao: 'nova'),
        session: _session,
      );

      expect(queueRepo.enqueued, isEmpty);
      expect(queueRepo.existingItems, hasLength(1));
      expect(queueRepo.existingItems.single.operation, SyncOperation.upsert);
    });
  });

  group('delete', () {
    test(
      'cria item delete no escopo da sessao quando nao ha pendencia',
      () async {
        await sut.delete(_makeRat(id: 'rat-1'), session: _session);

        expect(queueRepo.enqueued, hasLength(1));
        final item = queueRepo.enqueued.single;
        expect(item.operation, SyncOperation.delete);
        expect(item.usuarioId, 'user-1');
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        expect(payload['deletado'], isTrue);
      },
    );

    test('delete posterior substitui pending upsert (RF-09)', () async {
      queueRepo.existingItems.add(_syncItem(operation: SyncOperation.upsert));

      await sut.delete(_makeRat(id: 'rat-1'), session: _session);

      expect(queueRepo.enqueued, isEmpty);
      expect(queueRepo.existingItems, hasLength(1));
      expect(queueRepo.existingItems.single.operation, SyncOperation.delete);
    });
  });

  group('RF-08: consistencia sessao x RAT', () {
    test('rejeita empresa da sessao diferente da RAT', () async {
      const outraEmpresa = SyncSessionContext(
        empresaId: 'emp-OUTRA',
        usuarioId: 'user-1',
      );

      expect(
        () => sut.upsert(_makeRat(id: 'rat-1'), session: outraEmpresa),
        throwsStateError,
      );
      expect(queueRepo.replaceCalls, isEmpty);
      expect(queueRepo.enqueued, isEmpty);
    });

    test('rejeita sessao sem usuarioId', () async {
      const semUsuario = SyncSessionContext(empresaId: 'emp-1', usuarioId: '');

      expect(
        () => sut.upsert(_makeRat(id: 'rat-1'), session: semUsuario),
        throwsStateError,
      );
      expect(queueRepo.replaceCalls, isEmpty);
      expect(queueRepo.enqueued, isEmpty);
    });

    test('rejeita RAT sem vinculo remoto completo', () async {
      expect(
        () => sut.upsert(
          _makeRat(id: 'rat-1', tecnicoId: null),
          session: _session,
        ),
        throwsStateError,
      );
      expect(queueRepo.replaceCalls, isEmpty);
      expect(queueRepo.enqueued, isEmpty);
    });

    test('nao substitui item existente quando a validacao falha', () async {
      queueRepo.existingItems.add(_syncItem());
      const outraEmpresa = SyncSessionContext(
        empresaId: 'emp-OUTRA',
        usuarioId: 'user-1',
      );

      await expectLater(
        () => sut.upsert(_makeRat(id: 'rat-1'), session: outraEmpresa),
        throwsStateError,
      );
      expect(queueRepo.replaceCalls, isEmpty);
      expect(queueRepo.existingItems.single.usuarioId, 'user-1');
    });
  });
}

Rat _makeRat({
  required String id,
  String descricao = 'descricao',
  String? usuarioId = 'user-1',
  String? tecnicoId = 'tec-1',
  String? motivoReabertura,
  DateTime? reabertaParaCorrecaoEm,
  String? reabertaParaCorrecaoPorUserId,
  DateTime? assinaturaInvalidadaEm,
  String? assinaturaInvalidadaPorUserId,
}) {
  final now = DateTime(2026, 6, 26, 9);
  return Rat(
    id: id,
    authorId: 'author-1',
    empresaId: 'emp-1',
    usuarioId: usuarioId,
    tecnicoId: tecnicoId,
    ownerType: RatOwnerType.companyTecnico,
    numero: '0001',
    clienteNome: 'Cliente',
    responsavelRecebimento: 'Responsavel',
    dataVisita: now,
    horarioInicioAtendimento: '08:00',
    horarioTerminoAtendimento: '09:00',
    descricao: descricao,
    status: RatStatus.draft,
    syncStatus: RatSyncStatus.pendingSync,
    createdAt: now,
    updatedAt: now,
    reabertaParaCorrecaoEm: reabertaParaCorrecaoEm,
    reabertaParaCorrecaoPorUserId: reabertaParaCorrecaoPorUserId,
    motivoReabertura: motivoReabertura,
    assinaturaInvalidadaEm: assinaturaInvalidadaEm,
    assinaturaInvalidadaPorUserId: assinaturaInvalidadaPorUserId,
  );
}

SyncItem _syncItem({
  String payload = '{"id":"rat-1"}',
  String usuarioId = 'user-1',
  SyncOperation operation = SyncOperation.upsert,
  SyncItemStatus status = SyncItemStatus.pending,
  int attempts = 0,
  String? lastError,
  DateTime? nextAttemptAt,
}) {
  final now = DateTime(2026, 6, 26, 8);
  return SyncItem(
    id: 'sync-1',
    empresaId: 'emp-1',
    usuarioId: usuarioId,
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
