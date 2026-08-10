import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/data/repositories/drift_rat_repository.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/permissions/rat_permissions.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/restore_rat.dart';
import 'package:techreport/shared/infra/database/tech_report_local_database.dart'
    hide Rat;

void main() {
  group('RestoreRat', () {
    test('restaura RAT local sem substituir o snapshot', () async {
      final before = _deletedRat(ownerType: RatOwnerType.localTecnico);
      final repository = _RecordingRatRepository(before);
      final restore = RestoreRat(
        ratRepository: repository,
        permissions: const RatPermissions(),
      );

      final after = await restore(ratId: before.id, session: null);

      expect(after.deletedAt, isNull);
      expect(after.syncStatus, RatSyncStatus.localOnly);
      _expectSnapshotPreserved(before, after);
      expect(repository.restoreCalls, [(before.id, RatSyncStatus.localOnly)]);
      expect(repository.saveCalls, 0);
      expect(repository.updateCalls, 0);
    });

    test('restaura RAT da empresa como pendingSync', () async {
      final before = _deletedRat();
      final repository = _RecordingRatRepository(before);
      final restore = RestoreRat(
        ratRepository: repository,
        permissions: const RatPermissions(),
      );

      final after = await restore(ratId: before.id, session: _session());

      expect(after.deletedAt, isNull);
      expect(after.syncStatus, RatSyncStatus.pendingSync);
      _expectSnapshotPreserved(before, after);
      expect(repository.restoreCalls, [(before.id, RatSyncStatus.pendingSync)]);
    });

    test(
      'nega empresa divergente e modo incompatível antes da escrita',
      () async {
        final cases = <(Rat, SessaoRemota?)>[
          (_deletedRat(), _session(empresaId: 'outra-empresa')),
          (_deletedRat(), null),
          (_deletedRat(ownerType: RatOwnerType.localTecnico), _session()),
        ];

        for (final (rat, session) in cases) {
          final repository = _RecordingRatRepository(rat);
          final restore = RestoreRat(
            ratRepository: repository,
            permissions: const RatPermissions(),
          );

          await expectLater(
            restore(ratId: rat.id, session: session),
            throwsA(isA<RestoreRatAccessDeniedException>()),
          );
          expect(repository.restoreCalls, isEmpty);
        }
      },
    );

    test('RAT ausente gera falha tipada sem escrita', () async {
      final repository = _RecordingRatRepository(null);
      final restore = RestoreRat(
        ratRepository: repository,
        permissions: const RatPermissions(),
      );

      await expectLater(
        restore(ratId: 'ausente', session: null),
        throwsA(isA<RestoreRatNotFoundException>()),
      );
      expect(repository.restoreCalls, isEmpty);
    });

    test('Drift altera somente deletedAt e syncStatus', () async {
      final database = TechReportLocalDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftRatRepository(database);
      final before = _deletedRat(ownerType: RatOwnerType.localTecnico);
      await repository.save(before);
      final persistedBefore = await repository.getById(before.id);
      expect(persistedBefore, isNotNull);

      await repository.restore(
        id: before.id,
        syncStatus: RatSyncStatus.localOnly,
      );

      final after = await repository.getById(before.id);
      expect(after, isNotNull);
      expect(after!.deletedAt, isNull);
      expect(after.syncStatus, RatSyncStatus.localOnly);
      _expectSnapshotPreserved(persistedBefore!, after);
    });
  });
}

class _RecordingRatRepository implements RatRepository {
  _RecordingRatRepository(this.rat);

  Rat? rat;
  final List<(String, RatSyncStatus)> restoreCalls = [];
  int saveCalls = 0;
  int updateCalls = 0;

  @override
  Future<Rat?> getById(String id) async => rat;

  @override
  Future<void> restore({
    required String id,
    required RatSyncStatus syncStatus,
  }) async {
    restoreCalls.add((id, syncStatus));
  }

  @override
  Future<void> save(Rat rat) async => saveCalls++;

  @override
  Future<void> update(Rat rat) async => updateCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Rat _deletedRat({RatOwnerType ownerType = RatOwnerType.companyTecnico}) {
  final company = ownerType == RatOwnerType.companyTecnico;
  return Rat(
    id: 'rat-1',
    authorId: 'author-1',
    empresaId: company ? 'empresa-1' : null,
    usuarioId: company ? 'usuario-1' : null,
    tecnicoId: company ? 'tecnico-1' : null,
    ownerType: ownerType,
    numero: 'RAT-001',
    clienteNome: 'Cliente',
    responsavelRecebimento: 'Responsável',
    responsavelDocumento: '123',
    dataVisita: DateTime.utc(2026, 8, 2),
    horarioInicioAtendimento: '08:00',
    horarioTerminoAtendimento: '09:30',
    descricao: 'Descrição preservada',
    equipamentoMovimentoTipo: EquipamentoMovimentoTipo.retiradaParaReparo,
    equipamentoDescricao: 'Equipamento',
    equipamentoObservacao: 'Observação',
    status: RatStatus.finalizado,
    syncStatus: RatSyncStatus.synced,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 8),
    deletedAt: DateTime.utc(2026, 8, 9),
    ultimoAlteradorUserId: 'gerente-1',
    ultimaAlteracaoEm: DateTime.utc(2026, 8, 8),
    reabertaParaCorrecaoEm: DateTime.utc(2026, 8, 7),
    reabertaParaCorrecaoPorUserId: 'gerente-1',
    motivoReabertura: 'Correção autorizada',
    assinaturaInvalidadaEm: DateTime.utc(2026, 8, 7),
    assinaturaInvalidadaPorUserId: 'gerente-1',
  );
}

SessaoRemota _session({String empresaId = 'empresa-1'}) {
  final now = DateTime.utc(2026, 8, 10);
  return SessaoRemota(
    id: 'session-1',
    empresaId: empresaId,
    usuarioId: 'usuario-1',
    tecnicoId: 'tecnico-1',
    email: 'user@example.com',
    nome: 'Usuário',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: SessaoRemotaPapelEmpresa.tecnico,
    accessTokenRef: 'access-token',
    refreshTokenRef: 'refresh-token',
    endpointRef: 'endpoint',
    expiresAt: now.add(const Duration(hours: 1)),
    lastValidatedAt: now,
    offlineAccessUntil: now.add(const Duration(days: 7)),
    createdAt: now,
    updatedAt: now,
  );
}

void _expectSnapshotPreserved(Rat before, Rat after) {
  expect(after.id, before.id);
  expect(after.authorId, before.authorId);
  expect(after.empresaId, before.empresaId);
  expect(after.usuarioId, before.usuarioId);
  expect(after.tecnicoId, before.tecnicoId);
  expect(after.ownerType, before.ownerType);
  expect(after.numero, before.numero);
  expect(after.clienteNome, before.clienteNome);
  expect(after.responsavelRecebimento, before.responsavelRecebimento);
  expect(after.responsavelDocumento, before.responsavelDocumento);
  expect(after.dataVisita, before.dataVisita);
  expect(after.horarioInicioAtendimento, before.horarioInicioAtendimento);
  expect(after.horarioTerminoAtendimento, before.horarioTerminoAtendimento);
  expect(after.descricao, before.descricao);
  expect(after.equipamentoMovimentoTipo, before.equipamentoMovimentoTipo);
  expect(after.equipamentoDescricao, before.equipamentoDescricao);
  expect(after.equipamentoObservacao, before.equipamentoObservacao);
  expect(after.status, before.status);
  expect(after.createdAt, before.createdAt);
  expect(after.updatedAt, before.updatedAt);
  expect(after.ultimoAlteradorUserId, before.ultimoAlteradorUserId);
  expect(after.ultimaAlteracaoEm, before.ultimaAlteracaoEm);
  expect(after.reabertaParaCorrecaoEm, before.reabertaParaCorrecaoEm);
  expect(
    after.reabertaParaCorrecaoPorUserId,
    before.reabertaParaCorrecaoPorUserId,
  );
  expect(after.motivoReabertura, before.motivoReabertura);
  expect(after.assinaturaInvalidadaEm, before.assinaturaInvalidadaEm);
  expect(
    after.assinaturaInvalidadaPorUserId,
    before.assinaturaInvalidadaPorUserId,
  );
}
