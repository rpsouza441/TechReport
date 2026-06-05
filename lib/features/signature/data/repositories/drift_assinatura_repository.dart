import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart'
    as domain;
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/shared/infra/database/tech_report_local_database.dart';

class DriftAssinaturaRepository implements AssinaturaRepository {
  DriftAssinaturaRepository(this._database);

  final TechReportLocalDatabase _database;

  final LocalSignatureAssetStore _legacyStore = LocalSignatureAssetStore();

  @override
  Future<void> delete(String id) async {
    final current = await getById(id);

    if (current == null) {
      return;
    }

    final deleted = current.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await update(deleted);
  }

  @override
  Future<domain.Assinatura?> getById(String id) async {
    final row = await (_database.select(
      _database.assinaturas,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    if (row == null) {
      return null;
    }
    return _toEntity(row);
  }

  @override
  Future<List<domain.Assinatura>> listByRatId(String ratId) async {
    final rows = await (_database.select(
      _database.assinaturas,
    )..where((tbl) => tbl.ratId.equals(ratId) & tbl.deletedAt.isNull())).get();

    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> update(domain.Assinatura assinatura) async {
    await _database
        .into(_database.assinaturas)
        .insertOnConflictUpdate(_toCompanionPreservingBlob(assinatura));
  }

  @override
  Future<void> save(domain.Assinatura assinatura) async {
    await _database
        .into(_database.assinaturas)
        .insertOnConflictUpdate(_toCompanion(assinatura));
  }

  @override
  Future<Uint8List?> readBytes(String id) async {
    final row = await (_database.select(
      _database.assinaturas,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    if (row.storageMode == 'inlineBinary' && row.dataBlob != null) {
      return row.dataBlob!;
    }

    if (row.storageMode == 'localFile') {
      final bytes = await _legacyStore.read(row.assetRef);
      if (bytes != null) {
        return bytes;
      }
    }

    return null;
  }

  @override
  Future<void> saveBytes({
    required String assinaturaId,
    required Uint8List bytes,
    required String assetRef,
    required String ratId,
  }) async {
    final sha256Hash = sha256.convert(bytes).toString();
    final now = DateTime.now();

    final existing = await getById(assinaturaId);

    final assinatura = domain.Assinatura(
      id: assinaturaId,
      ratId: ratId.isNotEmpty ? ratId : (existing?.ratId ?? ''),
      storageMode: domain.StorageMode.inlineBinary,
      assetRef: assetRef,
      data: bytes,
      sizeBytes: bytes.length,
      sha256: sha256Hash,
      mimeType: 'image/png',
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      deletedAt: existing?.deletedAt,
    );

    await _database.into(_database.assinaturas).insert(
      AssinaturasCompanion(
        id: Value(assinatura.id),
        ratId: Value(assinatura.ratId),
        storageMode: Value(assinatura.storageMode.name),
        assetRef: Value(assinatura.assetRef),
        dataBlob: Value(assinatura.data),
        sizeBytes: Value(assinatura.sizeBytes),
        sha256: Value(assinatura.sha256),
        mimeType: Value(assinatura.mimeType),
        createdAt: Value(assinatura.createdAt),
        updatedAt: Value(assinatura.updatedAt),
        deletedAt: Value(assinatura.deletedAt),
      ),
    );
  }

  domain.Assinatura _toEntity(Assinatura row) {
    return domain.Assinatura(
      id: row.id,
      ratId: row.ratId,
      storageMode: _toStorageMode(row.storageMode),
      assetRef: row.assetRef,
      data: row.dataBlob,
      sizeBytes: row.sizeBytes,
      sha256: row.sha256,
      mimeType: row.mimeType,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  AssinaturasCompanion _toCompanion(domain.Assinatura entity) {
    return AssinaturasCompanion(
      id: Value(entity.id),
      ratId: Value(entity.ratId),
      storageMode: Value(entity.storageMode.name),
      assetRef: Value(entity.assetRef),
      dataBlob: Value(entity.data),
      sizeBytes: Value(entity.sizeBytes),
      sha256: Value(entity.sha256),
      mimeType: Value(entity.mimeType),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      deletedAt: Value(entity.deletedAt),
    );
  }

  /// Usa insert (não insertOnConflictUpdate) para novos registros,
  /// evitando sobrescrever colunas BLOB existentes.
  AssinaturasCompanion _toCompanionPreservingBlob(domain.Assinatura entity) {
    return AssinaturasCompanion(
      id: Value(entity.id),
      ratId: Value(entity.ratId),
      storageMode: Value(entity.storageMode.name),
      assetRef: Value(entity.assetRef),
      dataBlob: entity.data != null ? Value(entity.data) : const Value.absent(),
      sizeBytes: entity.sizeBytes != null
          ? Value(entity.sizeBytes)
          : const Value.absent(),
      sha256:
          entity.sha256 != null ? Value(entity.sha256) : const Value.absent(),
      mimeType: entity.mimeType != null
          ? Value(entity.mimeType)
          : const Value.absent(),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      deletedAt: Value(entity.deletedAt),
    );
  }

  domain.StorageMode _toStorageMode(String value) {
    switch (value) {
      case 'localFile':
        return domain.StorageMode.localFile;
      case 'inlineBinary':
        return domain.StorageMode.inlineBinary;
      case 'remoteAsset':
        return domain.StorageMode.remoteAsset;
      default:
        throw ArgumentError('StorageMode invalido: $value');
    }
  }
}