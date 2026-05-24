import 'package:drift/drift.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart' as domain;
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/shared/infra/database/tech_report_local_database.dart'
    as database;

class DriftRatRepository implements RatRepository {
  DriftRatRepository(this._database);

  final database.TechReportLocalDatabase _database;

  @override
  Future<domain.Rat?> getByIdScoped({
    required String id,
    required RatListScope scope,
  }) async {
    final query = _database.select(_database.rats)
      ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull());

    switch (scope.type) {
      case RatListScopeType.local:
        query.where(
          (tbl) => tbl.ownerType.equals(RatOwnerType.localTecnico.name),
        );
      case RatListScopeType.companyTechnician:
        query
          ..where((tbl) => tbl.empresaId.equals(scope.empresaId!))
          ..where((tbl) => tbl.tecnicoId.equals(scope.tecnicoId!))
          ..where(
            (tbl) => tbl.ownerType.equals(RatOwnerType.companyTecnico.name),
          );
      case RatListScopeType.companyManager:
        query
          ..where((tbl) => tbl.empresaId.equals(scope.empresaId!))
          ..where(
            (tbl) => tbl.ownerType.equals(RatOwnerType.companyTecnico.name),
          );
    }

    final row = await query.getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

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
  Future<List<domain.Rat>> listLocal() async {
    final rows =
        await (_database.select(_database.rats)
              ..where(
                (tbl) =>
                    tbl.deletedAt.isNull() &
                    tbl.ownerType.equals(RatOwnerType.localTecnico.name),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
            .get();

    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<domain.Rat>> listCompanyForTechnician({
    required String empresaId,
    required String tecnicoId,
  }) async {
    final rows =
        await (_database.select(_database.rats)
              ..where(
                (tbl) =>
                    tbl.deletedAt.isNull() &
                    tbl.ownerType.equals(RatOwnerType.companyTecnico.name) &
                    tbl.empresaId.equals(empresaId) &
                    tbl.tecnicoId.equals(tecnicoId),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
            .get();

    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<domain.Rat>> listCompanyForManager({
    required String empresaId,
  }) async {
    final rows =
        await (_database.select(_database.rats)
              ..where(
                (tbl) =>
                    tbl.deletedAt.isNull() &
                    tbl.ownerType.equals(RatOwnerType.companyTecnico.name) &
                    tbl.empresaId.equals(empresaId),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
            .get();

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

  domain.Rat _toEntity(database.Rat row) {
    return domain.Rat(
      id: row.id,
      authorId: row.authorId,
      empresaId: row.empresaId,
      usuarioId: row.usuarioId,
      tecnicoId: row.tecnicoId,
      ownerType: _toOwnerType(row.ownerType),
      numero: row.numero,
      clienteNome: row.clienteNome,
      responsavelRecebimento: row.responsavelRecebimento,
      dataVisita: row.dataVisita,
      horarioInicioAtendimento: row.horarioInicioAtendimento,
      horarioTerminoAtendimento: row.horarioTerminoAtendimento,
      descricao: row.descricao,
      equipamentoMovimentoTipo: _toEquipamentoMovimentoTipo(
        row.equipamentoMovimentoTipo,
      ),
      equipamentoDescricao: row.equipamentoDescricao,
      equipamentoObservacao: row.equipamentoObservacao,
      status: _toStatus(row.status),
      syncStatus: _toSyncStatus(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  database.RatsCompanion _toCompanion(domain.Rat entity) {
    return database.RatsCompanion(
      id: Value(entity.id),
      authorId: Value(entity.authorId),
      empresaId: Value(entity.empresaId),
      usuarioId: Value(entity.usuarioId),
      tecnicoId: Value(entity.tecnicoId),
      ownerType: Value(entity.ownerType.name),
      numero: Value(entity.numero),
      clienteNome: Value(entity.clienteNome),
      responsavelRecebimento: Value(entity.responsavelRecebimento),
      dataVisita: Value(entity.dataVisita),
      horarioInicioAtendimento: Value(entity.horarioInicioAtendimento),
      horarioTerminoAtendimento: Value(entity.horarioTerminoAtendimento),
      descricao: Value(entity.descricao),
      equipamentoMovimentoTipo: Value(entity.equipamentoMovimentoTipo?.name),
      equipamentoDescricao: Value(entity.equipamentoDescricao),
      equipamentoObservacao: Value(entity.equipamentoObservacao),
      status: Value(entity.status.name),
      syncStatus: Value(entity.syncStatus.name),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      deletedAt: Value(entity.deletedAt),
    );
  }

  domain.EquipamentoMovimentoTipo? _toEquipamentoMovimentoTipo(String? value) {
    switch (value) {
      case null:
        return null;
      case 'nenhum':
        return domain.EquipamentoMovimentoTipo.nenhum;
      case 'retiradaParaReparo':
        return domain.EquipamentoMovimentoTipo.retiradaParaReparo;
      case 'entregaPosReparo':
        return domain.EquipamentoMovimentoTipo.entregaPosReparo;
      case 'entregaPosCompra':
        return domain.EquipamentoMovimentoTipo.entregaPosCompra;
      default:
        throw ArgumentError('EquipamentoMovimentoTipo invalido: $value');
    }
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
      case 'companyTecnico':
        return domain.RatOwnerType.companyTecnico;
      default:
        throw ArgumentError('RatOwnerType invalido: $value');
    }
  }
}
