import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/signature/domain/repositories/remote_assinatura_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/usecases/process_assinatura_sync.dart';

class _StubAssinaturaRepository implements AssinaturaRepository {
  Uint8List? _bytesToReturn;
  List<String> _readHistory = [];

  void setBytesToReturn(Uint8List? bytes) {
    _bytesToReturn = bytes;
  }

  List<String> get readHistory => _readHistory;

  @override
  Future<Uint8List?> readBytes(String assinaturaId) async {
    _readHistory.add(assinaturaId);
    return _bytesToReturn;
  }

  @override
  Future<Assinatura?> getById(String id) async => null;
  @override
  Future<void> save(Assinatura assinatura) async {}
  @override
  Future<void> update(Assinatura assinatura) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> deleteByRatId(String ratId) async {}
  @override
  Future<List<Assinatura>> listByRatId(String ratId) async => [];
  @override
  Future<void> saveBytes({
    required String assinaturaId,
    required List<int> bytes,
    required String assetRef,
    required String ratId,
  }) async {}
  @override
  Future<void> saveInline({
    required String assinaturaId,
    required Assinatura assinatura,
  }) async {}
}

class _StubRemoteAssinaturaRepository
    implements RemoteAssinaturaRepository {
  final List<_UploadCall> uploads = [];
  final List<_DeleteCall> deletes = [];

  @override
  Future<String> uploadSignature({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
    required int version,
    required List<int> bytes,
    required String mimeType,
  }) async {
    uploads.add(_UploadCall(
      empresaId: empresaId,
      ratId: ratId,
      assinaturaId: assinaturaId,
      version: version,
      bytesLength: bytes.length,
      mimeType: mimeType,
    ));
    return '$empresaId/$ratId/$assinaturaId/v$version.png';
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
      'https://signed.url';

  @override
  Future<bool> objectExists(String storagePath) async => false;

  @override
  Future<void> markDeleted({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
  }) async {
    deletes.add(_DeleteCall(
      empresaId: empresaId,
      ratId: ratId,
      assinaturaId: assinaturaId,
    ));
  }
}

class _UploadCall {
  final String empresaId, ratId, assinaturaId, mimeType;
  final int version, bytesLength;
  _UploadCall({
    required this.empresaId,
    required this.ratId,
    required this.assinaturaId,
    required this.version,
    required this.bytesLength,
    required this.mimeType,
  });
}

class _DeleteCall {
  final String empresaId, ratId, assinaturaId;
  _DeleteCall({
    required this.empresaId,
    required this.ratId,
    required this.assinaturaId,
  });
}

class _StubSyncQueueRepository implements SyncQueueRepository {
  @override
  Future<bool> hasPendingItem({
    required String empresaId,
    required String usuarioId,
    required SyncEntityType entityType,
    required String entityId,
  }) async =>
      false;

  @override
  Future<void> enqueue(SyncItem item) async {}
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

SyncItem _buildUpsertItem({
  required String empresaId,
  required String ratId,
  required String assinaturaId,
}) {
  return SyncItem(
    id: 'sync-1',
    empresaId: empresaId,
    usuarioId: 'user-1',
    entityType: SyncEntityType.assinatura,
    entityId: assinaturaId,
    operation: SyncOperation.upsert,
    payload: '{"empresaId":"$empresaId","ratId":"$ratId","assinaturaId":"$assinaturaId","sizeBytes":1024,"mimeType":"image/png","deletedAt":null}',
    status: SyncItemStatus.pending,
    attempts: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

SyncItem _buildDeleteItem({
  required String empresaId,
  required String ratId,
  required String assinaturaId,
}) {
  return SyncItem(
    id: 'sync-2',
    empresaId: empresaId,
    usuarioId: 'user-1',
    entityType: SyncEntityType.assinatura,
    entityId: assinaturaId,
    operation: SyncOperation.delete,
    payload: '{"empresaId":"$empresaId","ratId":"$ratId","assinaturaId":"$assinaturaId","deletedAt":"${DateTime.now().toIso8601String()}"}',
    status: SyncItemStatus.pending,
    attempts: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  late _StubAssinaturaRepository assinaturaRepo;
  late _StubRemoteAssinaturaRepository remoteRepo;
  late ProcessAssinaturaSync sut;

  setUp(() {
    assinaturaRepo = _StubAssinaturaRepository();
    remoteRepo = _StubRemoteAssinaturaRepository();
    sut = ProcessAssinaturaSync(
      assinaturaRepository: assinaturaRepo,
      remoteAssinaturaRepository: remoteRepo,
    );
  });

  group('ProcessAssinaturaSync upsert', () {
    test('lê bytes do repositório local e faz upload', () async {
      final bytes = Uint8List.fromList(List<int>.generate(512, (i) => i % 256));
      assinaturaRepo.setBytesToReturn(bytes);

      await sut.call(_buildUpsertItem(
        empresaId: 'emp-1',
        ratId: 'rat-1',
        assinaturaId: 'assinatura-1',
      ));

      expect(assinaturaRepo.readHistory, ['assinatura-1']);
      expect(remoteRepo.uploads, hasLength(1));
      expect(remoteRepo.uploads.first.empresaId, 'emp-1');
      expect(remoteRepo.uploads.first.ratId, 'rat-1');
      expect(remoteRepo.uploads.first.assinaturaId, 'assinatura-1');
      expect(remoteRepo.uploads.first.version, 1);
      expect(remoteRepo.uploads.first.bytesLength, 512);
    });

    test('lança StateError quando bytes são null', () async {
      assinaturaRepo.setBytesToReturn(null);

      expect(
        () => sut.call(_buildUpsertItem(
          empresaId: 'emp-1',
          ratId: 'rat-1',
          assinaturaId: 'assinatura-1',
        )),
        throwsA(isA<StateError>()),
      );

      expect(remoteRepo.uploads, isEmpty);
    });

    test('delete operation não lê bytes', () async {
      assinaturaRepo.setBytesToReturn(null);

      await sut.call(_buildDeleteItem(
        empresaId: 'emp-1',
        ratId: 'rat-1',
        assinaturaId: 'assinatura-1',
      ));

      expect(assinaturaRepo.readHistory, isEmpty);
    });
  });

  group('ProcessAssinaturaSync delete', () {
    test('chama markDeleted no repositório remoto', () async {
      await sut.call(_buildDeleteItem(
        empresaId: 'emp-1',
        ratId: 'rat-1',
        assinaturaId: 'assinatura-1',
      ));

      expect(remoteRepo.deletes, hasLength(1));
      expect(remoteRepo.deletes.first.empresaId, 'emp-1');
      expect(remoteRepo.deletes.first.ratId, 'rat-1');
      expect(remoteRepo.deletes.first.assinaturaId, 'assinatura-1');
    });
  });
}
