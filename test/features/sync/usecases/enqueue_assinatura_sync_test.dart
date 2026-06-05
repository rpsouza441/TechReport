import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';

class _StubSyncQueueRepository implements SyncQueueRepository {
  final List<SyncItem> enqueued = [];
  bool hasPendingItemReturn = false;
  bool hasPendingItemCalled = false;
  String? lastHasPendingEmpresaId;
  String? lastHasPendingUsuarioId;
  SyncEntityType? lastHasPendingEntityType;
  String? lastHasPendingEntityId;

  @override
  Future<bool> hasPendingItem({
    required String empresaId,
    required String usuarioId,
    required SyncEntityType entityType,
    required String entityId,
  }) async {
    hasPendingItemCalled = true;
    lastHasPendingEmpresaId = empresaId;
    lastHasPendingUsuarioId = usuarioId;
    lastHasPendingEntityType = entityType;
    lastHasPendingEntityId = entityId;
    return hasPendingItemReturn;
  }

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
  }) async =>
      [];
  @override
  Future<int> countPending({
    required String empresaId,
    required String usuarioId,
  }) async =>
      0;
  @override
  Future<void> markProcessing(String id) async {}
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
  }) async =>
      [];
}

void main() {
  late _StubSyncQueueRepository queueRepo;
  late EnqueueAssinaturaSync sut;

  setUp(() {
    queueRepo = _StubSyncQueueRepository();
    sut = EnqueueAssinaturaSync(queueRepository: queueRepo);
  });

  Assinatura _assinatura(String id) => Assinatura(
        id: id,
        ratId: 'rat-1',
        storageMode: StorageMode.inlineBinary,
        assetRef: 'signatures/$id.png',
        data: Uint8List.fromList([1, 2, 3]),
        sizeBytes: 3,
        sha256: null,
        mimeType: 'image/png',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  group('upsert', () {
    test('enfileira item quando não há pendente existente', () async {
      queueRepo.hasPendingItemReturn = false;

      await sut.upsert(
        _assinatura('assinatura-1'),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        ratId: 'rat-1',
      );

      expect(queueRepo.hasPendingItemCalled, isTrue);
      expect(queueRepo.lastHasPendingEntityType, SyncEntityType.assinatura);
      expect(queueRepo.lastHasPendingEntityId, 'assinatura-1');
      expect(queueRepo.enqueued, hasLength(1));
      expect(queueRepo.enqueued.first.operation, SyncOperation.upsert);
      expect(queueRepo.enqueued.first.entityType, SyncEntityType.assinatura);
      expect(queueRepo.enqueued.first.entityId, 'assinatura-1');
    });

    test('não enfileira quando já existe pendente (deduplicação)', () async {
      queueRepo.hasPendingItemReturn = true;

      await sut.upsert(
        _assinatura('assinatura-1'),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        ratId: 'rat-1',
      );

      expect(queueRepo.enqueued, isEmpty);
    });
  });

  group('delete', () {
    test('enfileira item quando não há pendente existente', () async {
      queueRepo.hasPendingItemReturn = false;

      await sut.delete(
        _assinatura('assinatura-1'),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        ratId: 'rat-1',
      );

      expect(queueRepo.enqueued, hasLength(1));
      expect(queueRepo.enqueued.first.operation, SyncOperation.delete);
      expect(queueRepo.enqueued.first.entityId, 'assinatura-1');
    });

    test('não enfileira quando já existe pendente (deduplicação)', () async {
      queueRepo.hasPendingItemReturn = true;

      await sut.delete(
        _assinatura('assinatura-1'),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        ratId: 'rat-1',
      );

      expect(queueRepo.enqueued, isEmpty);
    });
  });
}
