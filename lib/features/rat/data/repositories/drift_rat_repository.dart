import 'package:drift/drift.dart';

import '../../../../shared/infra/database/tech_report_local_database.dart';
import '../../domain/entities/rat.dart' as domain;
import 'rat_repository.dart';

class DriftRatRepository implements RatRepository {
  DriftRatRepository(this._database);

  final TechReportLocalDatabase _database;

  @override
  Future<domain.Rat?> getById(String id) async {
    final row = await (_database.select(
      _database.rats,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toEntity(row);
  }

  @override
  Future<List<domain.Rat>> listAll() async {
    final rows = await (_database.select(
      _database.rats,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)])).get();

    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> save(domain.Rat rat) async {
    await _database
        .into(_database.rats)
        .insertOnConflictUpdate(_toCompanion(rat));
  }

  @override
  Future<void> update(domain.Rat rat) async {
    await _database
        .into(_database.rats)
        .insertOnConflictUpdate(_toCompanion(rat));
  }

  domain.Rat _toEntity(Rat row) {
    return domain.Rat(
      id: row.id,
      authorId: row.authorId,
      ownerType: _toOwnerType(row.ownerType),
      numero: row.numero,
      clienteNome: row.clienteNome,
      descricao: row.descricao,
      status: _toStatus(row.status),
      syncStatus: _toSyncStatus(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  RatsCompanion _toCompanion(domain.Rat entity) {
    return RatsCompanion(
      id: Value(entity.id),
      authorId: Value(entity.authorId),
      ownerType: Value(entity.ownerType.name),
      numero: Value(entity.numero),
      clienteNome: Value(entity.clienteNome),
      descricao: Value(entity.descricao),
      status: Value(entity.status.name),
      syncStatus: Value(entity.syncStatus.name),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      deletedAt: Value(entity.deletedAt),
    );
  }

  domain.RatStatus _toStatus(String value) {
    switch (value) {
      case 'draft':
        return domain.RatStatus.draft;
      case 'finalizado':
        return domain.RatStatus.finalizado;
      case 'enviado':
        return domain.RatStatus.enviado;
      case 'arquivado':
        return domain.RatStatus.arquivado;
      default:
        throw ArgumentError('RatStatus invalido: $value');
    }
  }

  domain.RatSyncStatus _toSyncStatus(String value) {
    switch (value) {
      case 'localOnly':
        return domain.RatSyncStatus.localOnly;
      case 'pendingSync':
        return domain.RatSyncStatus.pendingSync;
      case 'synced':
        return domain.RatSyncStatus.synced;
      case 'syncError':
        return domain.RatSyncStatus.syncError;
      default:
        throw ArgumentError('RatSyncStatus invalido: $value');
    }
  }

  domain.RatOwnerType _toOwnerType(String value) {
    switch (value) {
      case 'localTecnico':
        return domain.RatOwnerType.localTecnico;
      default:
        throw ArgumentError('RatOwnerType invalido: $value');
    }
  }
}
