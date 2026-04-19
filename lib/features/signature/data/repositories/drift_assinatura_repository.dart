import 'package:drift/drift.dart';

import 'package:techreport/features/signature/domain/entities/assinatura.dart'
    as domain;
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/shared/infra/database/tech_report_local_database.dart';

class DriftAssinaturaRepository implements AssinaturaRepository {
  DriftAssinaturaRepository(this._database);

  final TechReportLocalDatabase _database;

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
        .insertOnConflictUpdate(_toCompanion(assinatura));
  }

  @override
  Future<void> save(domain.Assinatura assinatura) async {
    await _database
        .into(_database.assinaturas)
        .insertOnConflictUpdate(_toCompanion(assinatura));
  }

  domain.Assinatura _toEntity(Assinatura row) {
    return domain.Assinatura(
      id: row.id,
      ratId: row.ratId,
      storageMode: _toStorageMode(row.storageMode),
      assetRef: row.assetRef,
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
