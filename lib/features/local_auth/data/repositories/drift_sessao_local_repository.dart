import 'package:drift/drift.dart';
import 'package:techreport/features/local_auth/domain/repositories/sessao_local_repository.dart';

import '../../../../shared/infra/database/tech_report_local_database.dart';
import '../../domain/entities/sessao_local.dart' as domain;

class DriftSessaoLocalRepository implements SessaoLocalRepository {
  DriftSessaoLocalRepository(this._database);

  final TechReportLocalDatabase _database;

  Future<void> delete() async {
    await _database.delete(_database.sessaoLocals).go();
  }

  @override
  Future<domain.SessaoLocal?> getCurrentSession() async {
    final rows = await (_database.select(
      _database.sessaoLocals,
    )..limit(1)).get();
    return rows.isEmpty ? null : _toEntity(rows.first);
  }

  @override
  Future<void> saveSession(domain.SessaoLocal session) async {
    await _database
        .into(_database.sessaoLocals)
        .insertOnConflictUpdate(_toCompanion(session));
  }

  @override
  Future<void> deleteSession() async {
    await _database.delete(_database.sessaoLocals).go();
  }

  domain.SessaoLocal _toEntity(SessaoLocal row) {
    return domain.SessaoLocal(
      id: row.id,
      tecnicoLocalId: row.tecnicoLocalId,
      status: _toStatus(row.status),
      pinConfigured: row.pinConfigured,
      biometriaDisponivel: row.biometriaDisponivel,
      biometriaHabilitada: row.biometriaHabilitada,
      onboardingConcluido: row.onboardingConcluido,
      lastUnlockedAt: row.lastUnlockedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  SessaoLocalsCompanion _toCompanion(domain.SessaoLocal entity) {
    return SessaoLocalsCompanion(
      id: Value(entity.id),
      mode: Value(entity.mode.name),
      tecnicoLocalId: Value(entity.tecnicoLocalId),
      status: Value(entity.status.name),
      pinConfigured: Value(entity.pinConfigured),
      biometriaDisponivel: Value(entity.biometriaDisponivel),
      biometriaHabilitada: Value(entity.biometriaHabilitada),
      onboardingConcluido: Value(entity.onboardingConcluido),
      lastUnlockedAt: Value(entity.lastUnlockedAt),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  domain.SessaoLocalStatus _toStatus(String value) {
    switch (value) {
      case 'onboardingRequired':
        return domain.SessaoLocalStatus.onboardingRequired;
      case 'locked':
        return domain.SessaoLocalStatus.locked;
      case 'unlocked':
        return domain.SessaoLocalStatus.unlocked;
      default:
        throw ArgumentError('SessaoLocalStatus invalido: $value');
    }
  }
}
