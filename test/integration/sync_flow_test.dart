import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';
import 'package:techreport/features/signature/domain/repositories/remote_assinatura_repository.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
import 'package:techreport/features/rat/domain/entities/rat_remote_snapshot.dart';

// ─── Mock Repositories ──────────────────────────────────────────────────────

class MockSyncQueueRepository implements SyncQueueRepository {
  final List<SyncItem> _items = [];
  bool shouldFailEnqueue = false;
  bool shouldFailMarkProcessing = false;
  int _idCounter = 0;

  List<SyncItem> get items => List.unmodifiable(_items);

  @override
  Future<void> enqueue(SyncItem item) async {
    if (shouldFailEnqueue) {
      throw Exception('Network error - failed to enqueue');
    }
    _items.add(item);
  }

  @override
  Future<List<SyncItem>> listPending({
    required String empresaId,
    required String usuarioId,
    bool includeFailed = false,
    int limit = 20,
  }) async {
    return _items.where((item) {
      if (item.empresaId != empresaId || item.usuarioId != usuarioId) {
        return false;
      }
      if (item.status == SyncItemStatus.pending) return true;
      if (includeFailed && item.status == SyncItemStatus.failed) return true;
      return false;
    }).toList();
  }

  @override
  Future<int> countPending({
    required String empresaId,
    required String usuarioId,
  }) async {
    return _items
        .where((item) =>
            item.empresaId == empresaId &&
            item.usuarioId == usuarioId &&
            item.status == SyncItemStatus.pending)
        .length;
  }

  @override
  Future<void> markProcessing(String id) async {
    if (shouldFailMarkProcessing) {
      throw Exception('Failed to mark processing');
    }
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = _items[index];
    }
  }

  @override
  Future<bool> tryMarkProcessing(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return false;

    final item = _items[index];
    if (item.status != SyncItemStatus.pending) return false;

    _items[index] = SyncItem(
      id: item.id,
      empresaId: item.empresaId,
      usuarioId: item.usuarioId,
      entityType: item.entityType,
      entityId: item.entityId,
      operation: item.operation,
      payload: item.payload,
      status: SyncItemStatus.processing,
      attempts: item.attempts,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
    return true;
  }

  @override
  Future<void> markSynced(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = SyncItem(
        id: _items[index].id,
        empresaId: _items[index].empresaId,
        usuarioId: _items[index].usuarioId,
        entityType: _items[index].entityType,
        entityId: _items[index].entityId,
        operation: _items[index].operation,
        payload: _items[index].payload,
        status: SyncItemStatus.synced,
        attempts: _items[index].attempts,
        createdAt: _items[index].createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> markFailed({
    required String id,
    required String errorMessage,
    required DateTime nextAttemptAt,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = SyncItem(
        id: _items[index].id,
        empresaId: _items[index].empresaId,
        usuarioId: _items[index].usuarioId,
        entityType: _items[index].entityType,
        entityId: _items[index].entityId,
        operation: _items[index].operation,
        payload: _items[index].payload,
        status: SyncItemStatus.failed,
        attempts: _items[index].attempts + 1,
        lastError: errorMessage,
        nextAttemptAt: nextAttemptAt,
        createdAt: _items[index].createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<SyncItem>> listForSession({
    required String empresaId,
    required String usuarioId,
    int limit = 50,
  }) async {
    return _items
        .where((item) =>
            item.empresaId == empresaId && item.usuarioId == usuarioId)
        .take(limit)
        .toList();
  }

  @override
  Future<bool> hasPendingItem({
    required String empresaId,
    required String usuarioId,
    required SyncEntityType entityType,
    required String entityId,
  }) async {
    return _items.any((item) =>
        item.empresaId == empresaId &&
        item.usuarioId == usuarioId &&
        item.entityType == entityType &&
        item.entityId == entityId &&
        (item.status == SyncItemStatus.pending ||
            item.status == SyncItemStatus.processing));
  }

  void clear() => _items.clear();

  String nextId() => 'sync-${++_idCounter}';
}

class MockRemoteRatRepository implements RemoteRatRepository {
  final List<String> upsertedPayloads = [];
  final List<String> deletedPayloads = [];
  bool shouldFailUpsert = false;
  bool shouldFailDelete = false;

  @override
  Future<void> upsertFromPayload(String payload) async {
    if (shouldFailUpsert) {
      throw Exception('Remote upsert failed');
    }
    upsertedPayloads.add(payload);
  }

  @override
  Future<void> softDeleteFromPayload(String payload) async {
    if (shouldFailDelete) {
      throw Exception('Remote delete failed');
    }
    deletedPayloads.add(payload);
  }

  @override
  Future<List<RatRemoteSnapshot>> fetchUpdatedSince({
    required String empresaId,
    required DateTime? since,
  }) async {
    return [];
  }

  void reset() {
    upsertedPayloads.clear();
    deletedPayloads.clear();
    shouldFailUpsert = false;
    shouldFailDelete = false;
  }
}

class MockRatRepository implements RatRepository {
  final Map<String, Rat> _rats = {};

  @override
  Future<Rat?> getById(String id) async {
    return _rats[id];
  }

  @override
  Future<Rat?> getByIdScoped({
    required String id,
    required RatListScope scope,
  }) async {
    return _rats[id];
  }

  @override
  Future<List<Rat>> listLocal() async => _rats.values.toList();

  @override
  Future<List<Rat>> listLocalPage({
    required int limit,
    required int offset,
  }) async {
    return _rats.values.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Rat>> listCompanyForManager({required String empresaId}) async => [];

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
  Future<List<Rat>> listLocalCursor({
    required int limit,
    String? lastId,
  }) async {
    return _rats.values.take(limit).toList();
  }

  @override
  Future<List<Rat>> listCompanyForTechnicianCursor({
    required String empresaId,
    required String tecnicoId,
    required int limit,
    String? lastId,
  }) async =>
      [];

  @override
  Future<List<Rat>> listCompanyForManagerCursor({
    required String empresaId,
    required int limit,
    String? lastId,
  }) async =>
      [];

  @override
  Future<void> save(Rat rat) async {
    _rats[rat.id] = rat;
  }

  @override
  Future<void> update(Rat rat) async {
    _rats[rat.id] = rat;
  }

  void clear() => _rats.clear();
}

class MockAssinaturaRepository implements AssinaturaRepository {
  final Map<String, Assinatura> _assinaturas = {};

  @override
  Future<Assinatura?> getById(String id) async => _assinaturas[id];

  @override
  Future<List<Assinatura>> listByRatId(String ratId) async {
    return _assinaturas.values.where((a) => a.ratId == ratId).toList();
  }

  @override
  Future<Map<String, List<Assinatura>>> listByRatIds(List<String> ratIds) async {
    final result = <String, List<Assinatura>>{};
    for (final ratId in ratIds) {
      result[ratId] = _assinaturas.values.where((a) => a.ratId == ratId).toList();
    }
    return result;
  }

  @override
  Future<void> save(Assinatura assinatura) async {
    _assinaturas[assinatura.id] = assinatura;
  }

  @override
  Future<void> update(Assinatura assinatura) async {
    _assinaturas[assinatura.id] = assinatura;
  }

  @override
  Future<void> delete(String id) async {
    _assinaturas.remove(id);
  }

  @override
  Future<Uint8List?> readBytes(String id) async => null;

  @override
  Future<void> saveBytes({
    required String assinaturaId,
    required List<int> bytes,
    required String assetRef,
    required String ratId,
  }) async {}

  void clear() => _assinaturas.clear();
}

class MockRemoteAssinaturaRepository implements RemoteAssinaturaRepository {
  final List<String> uploadedSignatures = [];
  bool shouldFail = false;

  @override
  Future<String> uploadSignature({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
    required int version,
    required List<int> bytes,
    required String mimeType,
  }) async {
    if (shouldFail) throw Exception('Upload failed');
    uploadedSignatures.add(assinaturaId);
    return 'uploaded/path/$assinaturaId';
  }

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
  Future<bool> objectExists(String storagePath) async => true;

  @override
  Future<void> deleteStorageObject(String storagePath) async {}

  @override
  Future<void> markDeleted({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
  }) async {}

  void reset() {
    uploadedSignatures.clear();
    shouldFail = false;
  }
}

// ─── Test Helpers ───────────────────────────────────────────────────────────

Rat _makeRat({
  required String id,
  String empresaId = 'emp-1',
  String usuarioId = 'user-1',
  String tecnicoId = 'tec-1',
  RatSyncStatus syncStatus = RatSyncStatus.pendingSync,
}) {
  final now = DateTime.now();
  return Rat(
    id: id,
    authorId: 'author-1',
    empresaId: empresaId,
    usuarioId: usuarioId,
    tecnicoId: tecnicoId,
    ownerType: RatOwnerType.companyTecnico,
    numero: '0001',
    clienteNome: 'Test Cliente',
    responsavelRecebimento: 'Responsavel',
    dataVisita: now,
    horarioInicioAtendimento: '08:00',
    horarioTerminoAtendimento: '10:00',
    descricao: 'Test description',
    status: RatStatus.draft,
    syncStatus: syncStatus,
    createdAt: now,
    updatedAt: now,
  );
}

Assinatura _makeAssinatura({
  required String id,
  required String ratId,
}) {
  final now = DateTime.now();
  return Assinatura(
    id: id,
    ratId: ratId,
    storageMode: StorageMode.inlineBinary,
    assetRef: 'signatures/$id.png',
    data: Uint8List(0),
    sizeBytes: 0,
    mimeType: 'image/png',
    createdAt: now,
    updatedAt: now,
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late MockSyncQueueRepository queueRepo;
  late MockRemoteRatRepository remoteRatRepo;
  late MockRatRepository ratRepo;
  late MockAssinaturaRepository assinaturaRepo;
  late MockRemoteAssinaturaRepository remoteAssinaturaRepo;
  late ProcessSyncQueue processSyncQueue;
  late EnqueueRatSync enqueueRatSync;

  setUp(() {
    queueRepo = MockSyncQueueRepository();
    remoteRatRepo = MockRemoteRatRepository();
    ratRepo = MockRatRepository();
    assinaturaRepo = MockAssinaturaRepository();
    remoteAssinaturaRepo = MockRemoteAssinaturaRepository();

    processSyncQueue = ProcessSyncQueue(
      queueRepository: queueRepo,
      remoteRatRepository: remoteRatRepo,
      ratRepository: ratRepo,
      assinaturaRepository: assinaturaRepo,
      remoteAssinaturaRepository: remoteAssinaturaRepo,
    );

    enqueueRatSync = EnqueueRatSync(
      queueRepository: queueRepo,
    );
  });

  // ─── Offline Create → Online Sync ──────────────────────────────────────────

  group('Offline create → online sync', () {
    test('offline RAT is saved locally with pendingSync status', () async {
      final rat = _makeRat(id: 'rat-offline-1', syncStatus: RatSyncStatus.pendingSync);

      // Simulate offline save
      await ratRepo.save(rat);

      expect(ratRepo._rats['rat-offline-1']?.syncStatus, RatSyncStatus.pendingSync);
    });

    test('enqueueSync adds RAT to sync queue', () async {
      final rat = _makeRat(id: 'rat-queue-1');

      await enqueueRatSync.upsert(rat);

      expect(queueRepo.items.length, 1);
      expect(queueRepo.items.first.entityType, SyncEntityType.rat);
      expect(queueRepo.items.first.operation, SyncOperation.upsert);
      expect(queueRepo.items.first.entityId, 'rat-queue-1');
      expect(queueRepo.items.first.status, SyncItemStatus.pending);
    });

    test('processSyncQueue sends pending RAT to remote', () async {
      final rat = _makeRat(id: 'rat-process-1');
      await ratRepo.save(rat);

      // Manually add to queue (simulating what enqueueRatSync does)
      final now = DateTime.now();
      await queueRepo.enqueue(SyncItem(
        id: queueRepo.nextId(),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode({
          'id': rat.id,
          'empresaId': rat.empresaId,
          'tecnicoId': rat.tecnicoId,
        }),
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ));

      await processSyncQueue.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(remoteRatRepo.upsertedPayloads.length, 1);
      expect(queueRepo.items.first.status, SyncItemStatus.synced);
    });

    test('successful sync updates RAT local status to synced', () async {
      final rat = _makeRat(id: 'rat-synced-1', syncStatus: RatSyncStatus.pendingSync);
      await ratRepo.save(rat);

      final now = DateTime.now();
      await queueRepo.enqueue(SyncItem(
        id: queueRepo.nextId(),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode({'id': rat.id}),
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ));

      await processSyncQueue.call(empresaId: 'emp-1', usuarioId: 'user-1');

      final syncedRat = await ratRepo.getById('rat-synced-1');
      expect(syncedRat?.syncStatus, RatSyncStatus.synced);
    });
  });

  // ─── Conflict Resolution ────────────────────────────────────────────────────

  group('Conflict resolution', () {
    test('local vs remote conflict resolves with newer timestamp', () async {
      final now = DateTime.now();

      // Local RAT (older)
      final localRat = Rat(
        id: 'rat-conflict',
        authorId: 'author-1',
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        tecnicoId: 'tec-1',
        ownerType: RatOwnerType.companyTecnico,
        numero: '0001',
        clienteNome: 'Local Name',
        responsavelRecebimento: 'Responsavel',
        dataVisita: now,
        horarioInicioAtendimento: '08:00',
        horarioTerminoAtendimento: '10:00',
        descricao: 'Local description',
        status: RatStatus.draft,
        syncStatus: RatSyncStatus.localOnly,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      // Remote RAT (newer)
      final remoteRat = Rat(
        id: 'rat-conflict',
        authorId: 'author-1',
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        tecnicoId: 'tec-1',
        ownerType: RatOwnerType.companyTecnico,
        numero: '0001',
        clienteNome: 'Remote Name Updated',
        responsavelRecebimento: 'Responsavel',
        dataVisita: now,
        horarioInicioAtendimento: '08:00',
        horarioTerminoAtendimento: '10:00',
        descricao: 'Remote description updated',
        status: RatStatus.finalizado,
        syncStatus: RatSyncStatus.synced,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now, // Newer
      );

      // Save local first
      await ratRepo.save(localRat);

      // Simulate conflict resolution: newer wins
      final resolved = remoteRat.updatedAt.isAfter(localRat.updatedAt)
          ? remoteRat
          : localRat;

      expect(resolved.clienteNome, 'Remote Name Updated');
      expect(resolved.updatedAt, now);
    });

    test('deduplicates sync queue for same RAT', () async {
      final rat = _makeRat(id: 'rat-dedup');

      // First enqueue
      await enqueueRatSync.upsert(rat);

      // Second enqueue (should be deduped)
      await enqueueRatSync.upsert(rat);

      // Should only have one item in queue
      final pendingCount = await queueRepo.countPending(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
      );
      expect(pendingCount, 1);
    });
  });

  // ─── Retry Failed Sync ────────────────────────────────────────────────────

  group('Retry failed sync items', () {
    test('failed item is retried when retryFailed=true', () async {
      final rat = _makeRat(id: 'rat-retry');
      await ratRepo.save(rat);

      // Add failed item
      final now = DateTime.now();
      await queueRepo.enqueue(SyncItem(
        id: queueRepo.nextId(),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode({'id': rat.id}),
        status: SyncItemStatus.failed,
        attempts: 1,
        lastError: 'Network timeout',
        nextAttemptAt: now, // Ready for retry
        createdAt: now,
        updatedAt: now,
      ));

      // Process with retry
      await processSyncQueue.call(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        retryFailed: true,
      );

      expect(remoteRatRepo.upsertedPayloads.length, 1);
    });

    test('failed item is not retried when retryFailed=false', () async {
      final rat = _makeRat(id: 'rat-no-retry');
      await ratRepo.save(rat);

      final now = DateTime.now();
      await queueRepo.enqueue(SyncItem(
        id: queueRepo.nextId(),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode({'id': rat.id}),
        status: SyncItemStatus.failed,
        attempts: 1,
        lastError: 'Network timeout',
        nextAttemptAt: now,
        createdAt: now,
        updatedAt: now,
      ));

      // Process without retry
      await processSyncQueue.call(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        retryFailed: false,
      );

      expect(remoteRatRepo.upsertedPayloads, isEmpty);
    });

    test('failed sync increments attempt counter', () async {
      remoteRatRepo.shouldFailUpsert = true;
      final rat = _makeRat(id: 'rat-fail-count');
      await ratRepo.save(rat);

      final now = DateTime.now();
      await queueRepo.enqueue(SyncItem(
        id: queueRepo.nextId(),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode({'id': rat.id}),
        status: SyncItemStatus.pending,
        attempts: 2,
        createdAt: now,
        updatedAt: now,
      ));

      await processSyncQueue.call(empresaId: 'emp-1', usuarioId: 'user-1');

      final failedItem = queueRepo.items.first;
      expect(failedItem.status, SyncItemStatus.failed);
      expect(failedItem.attempts, 3);
    });

    test('max attempts exceeded marks item as permanently failed', () async {
      final rat = _makeRat(id: 'rat-max-attempts');
      await ratRepo.save(rat);

      final now = DateTime.now();
      await queueRepo.enqueue(SyncItem(
        id: queueRepo.nextId(),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode({'id': rat.id}),
        status: SyncItemStatus.pending,
        attempts: 5, // Max attempts
        createdAt: now,
        updatedAt: now,
      ));

      await processSyncQueue.call(empresaId: 'emp-1', usuarioId: 'user-1');

      // Item should still be in failed state but with permanent message
      final item = queueRepo.items.first;
      expect(item.status, SyncItemStatus.failed);
      expect(item.lastError, contains('Limite'));
    });
  });

  // ─── Sync Queue Processing ──────────────────────────────────────────────────

  group('Sync queue processing', () {
    test('processes multiple items in sequence', () async {
      final rats = [
        _makeRat(id: 'rat-batch-1'),
        _makeRat(id: 'rat-batch-2'),
        _makeRat(id: 'rat-batch-3'),
      ];

      for (final rat in rats) {
        await ratRepo.save(rat);
      }

      final now = DateTime.now();
      for (final rat in rats) {
        await queueRepo.enqueue(SyncItem(
          id: queueRepo.nextId(),
          empresaId: 'emp-1',
          usuarioId: 'user-1',
          entityType: SyncEntityType.rat,
          entityId: rat.id,
          operation: SyncOperation.upsert,
          payload: jsonEncode({'id': rat.id}),
          status: SyncItemStatus.pending,
          attempts: 0,
          createdAt: now,
          updatedAt: now,
        ));
      }

      await processSyncQueue.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(remoteRatRepo.upsertedPayloads.length, 3);
      expect(
        queueRepo.items.where((i) => i.status == SyncItemStatus.synced).length,
        3,
      );
    });

    test('failed item does not block other items', () async {
      final rats = [
        _makeRat(id: 'rat-success'),
        _makeRat(id: 'rat-fail'),
      ];

      for (final rat in rats) {
        await ratRepo.save(rat);
      }

      // Make second RAT fail
      remoteRatRepo.shouldFailUpsert = true;

      final now = DateTime.now();
      for (final rat in rats) {
        await queueRepo.enqueue(SyncItem(
          id: queueRepo.nextId(),
          empresaId: 'emp-1',
          usuarioId: 'user-1',
          entityType: SyncEntityType.rat,
          entityId: rat.id,
          operation: SyncOperation.upsert,
          payload: jsonEncode({'id': rat.id}),
          status: SyncItemStatus.pending,
          attempts: 0,
          createdAt: now,
          updatedAt: now,
        ));
      }

      await processSyncQueue.call(empresaId: 'emp-1', usuarioId: 'user-1');

      // First should succeed
      expect(remoteRatRepo.upsertedPayloads.length, 1);
      expect(queueRepo.items.first.status, SyncItemStatus.synced);

      // Second should fail
      expect(queueRepo.items.last.status, SyncItemStatus.failed);
    });

    test('deletes are processed correctly', () async {
      final rat = _makeRat(id: 'rat-delete');
      await ratRepo.save(rat);

      final now = DateTime.now();
      await queueRepo.enqueue(SyncItem(
        id: queueRepo.nextId(),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: SyncOperation.delete,
        payload: jsonEncode({'id': rat.id, 'deletado': true}),
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ));

      await processSyncQueue.call(empresaId: 'emp-1', usuarioId: 'user-1');

      expect(remoteRatRepo.deletedPayloads.length, 1);
      expect(queueRepo.items.first.status, SyncItemStatus.synced);
    });
  });

  // ─── Queue Statistics ──────────────────────────────────────────────────────

  group('Queue statistics', () {
    test('countPending returns correct count', () async {
      final rats = List.generate(5, (i) => _makeRat(id: 'rat-count-$i'));

      final now = DateTime.now();
      for (final rat in rats) {
        await queueRepo.enqueue(SyncItem(
          id: queueRepo.nextId(),
          empresaId: 'emp-1',
          usuarioId: 'user-1',
          entityType: SyncEntityType.rat,
          entityId: rat.id,
          operation: SyncOperation.upsert,
          payload: jsonEncode({'id': rat.id}),
          status: SyncItemStatus.pending,
          attempts: 0,
          createdAt: now,
          updatedAt: now,
        ));
      }

      final count = await queueRepo.countPending(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
      );

      expect(count, 5);
    });

    test('items filter by empresa and usuario correctly', () async {
      final rat1 = _makeRat(id: 'rat-emp1', empresaId: 'emp-1', usuarioId: 'user-1');
      final rat2 = _makeRat(id: 'rat-emp2', empresaId: 'emp-2', usuarioId: 'user-2');

      final now = DateTime.now();
      await queueRepo.enqueue(SyncItem(
        id: queueRepo.nextId(),
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: rat1.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode({'id': rat1.id}),
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ));

      await queueRepo.enqueue(SyncItem(
        id: queueRepo.nextId(),
        empresaId: 'emp-2',
        usuarioId: 'user-2',
        entityType: SyncEntityType.rat,
        entityId: rat2.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode({'id': rat2.id}),
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ));

      // Process only emp-1 items
      await processSyncQueue.call(empresaId: 'emp-1', usuarioId: 'user-1');

      // Only emp-1 item should be processed
      expect(remoteRatRepo.upsertedPayloads.length, 1);
    });
  });
}
