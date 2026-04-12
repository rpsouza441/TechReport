import 'package:drift/drift.dart';

import '../../../../shared/infra/database/tech_report_local_database.dart';
import '../../domain/entities/tecnico_local.dart' as domain;
import '../../domain/repositories/tecnico_local_repository.dart';

class DriftTecnicoLocalRepository implements TecnicoLocalRepository {
  DriftTecnicoLocalRepository(this._database);

  final TechReportLocalDatabase _database;

  @override
  Future<domain.TecnicoLocal?> getCurrent() async {
    final rows = await (_database.select(
      _database.tecnicoLocals,
    )..limit(1)).get();
    return rows.isEmpty ? null : _toEntity(rows.first);
  }

  @override
  Future<void> save(domain.TecnicoLocal tecnicoLocal) async {
    await _database
        .into(_database.tecnicoLocals)
        .insertOnConflictUpdate(_toCompanion(tecnicoLocal));
  }

  domain.TecnicoLocal _toEntity(TecnicoLocal row) {
    return domain.TecnicoLocal(
      id: row.id,
      nome: row.nome,
      email: row.email,
      telefone: row.telefone,
      empresaNome: row.empresaNome,
      assinaturaPadraoRef: row.assinaturaPadraoRef,
      pinConfigured: row.pinConfigured,
      biometriaHabilitada: row.biometriaHabilitada,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TecnicoLocalsCompanion _toCompanion(domain.TecnicoLocal entity) {
    return TecnicoLocalsCompanion(
      id: Value(entity.id),
      nome: Value(entity.nome),
      email: Value(entity.email),
      telefone: Value(entity.telefone),
      empresaNome: Value(entity.empresaNome),
      assinaturaPadraoRef: Value(entity.assinaturaPadraoRef),
      pinConfigured: Value(entity.pinConfigured),
      biometriaHabilitada: Value(entity.biometriaHabilitada),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }
}
