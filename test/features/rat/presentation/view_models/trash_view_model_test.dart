import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/services/rat_sync_coordinator.dart';
import 'package:techreport/features/rat/presentation/view_models/trash_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/trash_view_model.dart';

void main() {
  group('escopo da lixeira', () {
    test('local carrega somente RATs locais excluidas', () async {
      final repository = _FakeRatRepository()
        ..pages.add([_deletedRat('rat-1')]);
      final viewModel = _viewModel(
        repository: repository,
        scope: const TrashScope.local(),
        session: null,
      );

      await viewModel.load();

      expect(repository.calls.single, 'local');
      expect(viewModel.rats.map((rat) => rat.id), ['rat-1']);
      expect(viewModel.isAccessDenied, isFalse);
    });

    test('tecnico carrega somente a lixeira pessoal da empresa', () async {
      final repository = _FakeRatRepository()
        ..pages.add([_deletedRat('rat-1')]);
      final viewModel = _viewModel(
        repository: repository,
        scope: const TrashScope.companyTechnician(
          empresaId: 'empresa-1',
          tecnicoId: 'tecnico-1',
        ),
        session: _session(),
      );

      await viewModel.load();

      expect(repository.calls.single, 'technician:empresa-1:tecnico-1');
      expect(viewModel.rats, hasLength(1));
    });

    test('gerente e admin carregam a lixeira da mesma empresa', () async {
      for (final role in [
        SessaoRemotaPapelEmpresa.gerente,
        SessaoRemotaPapelEmpresa.adminEmpresa,
      ]) {
        final repository = _FakeRatRepository()
          ..pages.add([_deletedRat('rat-$role')]);
        final viewModel = _viewModel(
          repository: repository,
          scope: const TrashScope.companyManager(empresaId: 'empresa-1'),
          session: _session(role: role),
        );

        await viewModel.load();

        expect(repository.calls.single, 'manager:empresa-1');
        expect(viewModel.rats, hasLength(1));
      }
    });

    test('app_admin e sessao cross-company exibem acesso negado', () async {
      for (final session in [
        _appAdminSession(),
        _session(empresaId: 'outra-empresa'),
      ]) {
        final repository = _FakeRatRepository();
        final viewModel = _viewModel(
          repository: repository,
          scope: const TrashScope.companyManager(empresaId: 'empresa-1'),
          session: session,
        );

        await viewModel.load();

        expect(viewModel.isAccessDenied, isTrue);
        expect(
          viewModel.errorMessage,
          'Você não tem permissão para acessar este conteúdo.',
        );
        expect(viewModel.rats, isEmpty);
        expect(repository.calls, isEmpty);
      }
    });
  });

  group('paginacao e erro com cache', () {
    test('cursor composto usa deletedAt e id do ultimo card', () async {
      final oldest = _deletedRat(
        'rat-2',
        deletedAt: DateTime.parse('2026-08-09T12:00:00Z'),
      );
      final repository = _FakeRatRepository()
        ..pages.add([
          _deletedRat(
            'rat-1',
            deletedAt: DateTime.parse('2026-08-09T13:00:00Z'),
          ),
          oldest,
        ])
        ..pages.add([_deletedRat('rat-3')]);
      final viewModel = _viewModel(
        repository: repository,
        scope: const TrashScope.local(),
        session: null,
        pageSize: 2,
      );

      await viewModel.load();
      await viewModel.loadMore();

      expect(repository.cursors, [null, (oldest.deletedAt, oldest.id)]);
      expect(viewModel.rats.map((rat) => rat.id), ['rat-1', 'rat-2', 'rat-3']);
    });

    test('erro de refresh preserva cards e mostra mensagem PT-BR', () async {
      final repository = _FakeRatRepository()
        ..pages.add([_deletedRat('rat-1')]);
      final viewModel = _viewModel(
        repository: repository,
        scope: const TrashScope.local(),
        session: null,
      );

      await viewModel.load();
      repository.error = Exception('falha de leitura');
      await viewModel.refresh();

      expect(viewModel.rats.map((rat) => rat.id), ['rat-1']);
      expect(viewModel.isRefreshing, isFalse);
      expect(
        viewModel.errorMessage,
        'Não foi possível carregar a lixeira local. Tente novamente.',
      );
    });
  });

  group('restore explicito e por card', () {
    test('apenas o card em restauracao fica bloqueado', () async {
      final repository = _FakeRatRepository()
        ..pages.add([_deletedRat('rat-1'), _deletedRat('rat-2')]);
      final coordinator = _FakeRatSyncCoordinator();
      final pending = Completer<RatRestoreSyncResult>();
      coordinator.nextResult = pending.future;
      final viewModel = _viewModel(
        repository: repository,
        coordinator: coordinator,
        scope: const TrashScope.local(),
        session: null,
      );
      await viewModel.load();

      final restore = viewModel.restore('rat-1');
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.restoringRatIds, {'rat-1'});
      expect(viewModel.rats.map((rat) => rat.id), ['rat-1', 'rat-2']);

      pending.complete(RatRestoreSyncResult.localCompleted);
      expect(await restore, TrashRestoreResult.localCompleted);
    });

    test(
      'sucesso remove somente o card e preserva ordem/conteudo restante',
      () async {
        final repository = _FakeRatRepository()
          ..pages.add([
            _deletedRat('rat-1'),
            _deletedRat('rat-2'),
            _deletedRat('rat-3'),
          ]);
        final coordinator = _FakeRatSyncCoordinator()
          ..result = RatRestoreSyncResult.remoteCompleted;
        final viewModel = _viewModel(
          repository: repository,
          coordinator: coordinator,
          scope: const TrashScope.companyTechnician(
            empresaId: 'empresa-1',
            tecnicoId: 'tecnico-1',
          ),
          session: _session(),
        );
        await viewModel.load();

        final result = await viewModel.restore('rat-2');

        expect(result, TrashRestoreResult.remoteCompleted);
        expect(viewModel.rats.map((rat) => rat.id), ['rat-1', 'rat-3']);
        expect(viewModel.restoringRatIds, isEmpty);
        expect(
          viewModel.feedbackMessage,
          'RAT restaurada com o status e a assinatura preservados.',
        );
      },
    );

    test('restore enfileirado usa mensagem offline aprovada', () async {
      final repository = _FakeRatRepository()
        ..pages.add([_deletedRat('rat-1')]);
      final coordinator = _FakeRatSyncCoordinator()
        ..result = RatRestoreSyncResult.queued;
      final viewModel = _viewModel(
        repository: repository,
        coordinator: coordinator,
        scope: const TrashScope.companyTechnician(
          empresaId: 'empresa-1',
          tecnicoId: 'tecnico-1',
        ),
        session: _session(),
      );
      await viewModel.load();

      final result = await viewModel.restore('rat-1');

      expect(result, TrashRestoreResult.queued);
      expect(
        viewModel.feedbackMessage,
        'RAT restaurada neste dispositivo. A sincronização será feita quando houver conexão.',
      );
    });

    test('falha mantem card e expõe mensagem acionavel', () async {
      final repository = _FakeRatRepository()
        ..pages.add([_deletedRat('rat-1')]);
      final coordinator = _FakeRatSyncCoordinator()
        ..error = Exception('restore falhou');
      final viewModel = _viewModel(
        repository: repository,
        coordinator: coordinator,
        scope: const TrashScope.local(),
        session: null,
      );
      await viewModel.load();

      final result = await viewModel.restore('rat-1');

      expect(result, TrashRestoreResult.failure);
      expect(viewModel.rats.map((rat) => rat.id), ['rat-1']);
      expect(
        viewModel.errorMessage,
        'Não foi possível restaurar a RAT. Tente novamente.',
      );
    });
  });
}

TrashViewModel _viewModel({
  required _FakeRatRepository repository,
  required TrashScope scope,
  required SessaoRemota? session,
  _FakeRatSyncCoordinator? coordinator,
  int pageSize = 20,
}) {
  return TrashViewModel(
    ratRepository: repository,
    syncCoordinator: coordinator ?? _FakeRatSyncCoordinator(),
    scope: scope,
    session: session,
    pageSize: pageSize,
  );
}

class _FakeRatRepository implements RatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final List<List<Rat>> pages = [];
  final List<String> calls = [];
  final List<(DateTime?, String?)?> cursors = [];
  Object? error;

  Future<List<Rat>> _page(
    String call, {
    DateTime? lastDeletedAt,
    String? lastId,
  }) async {
    calls.add(call);
    cursors.add(lastId == null ? null : (lastDeletedAt, lastId));
    if (error case final Object failure) throw failure;
    return pages.isEmpty ? [] : pages.removeAt(0);
  }

  @override
  Future<List<Rat>> listDeletedLocalCursor({
    required int limit,
    DateTime? lastDeletedAt,
    String? lastId,
  }) => _page('local', lastDeletedAt: lastDeletedAt, lastId: lastId);

  @override
  Future<List<Rat>> listDeletedCompanyForTechnicianCursor({
    required String empresaId,
    required String tecnicoId,
    required int limit,
    DateTime? lastDeletedAt,
    String? lastId,
  }) => _page(
    'technician:$empresaId:$tecnicoId',
    lastDeletedAt: lastDeletedAt,
    lastId: lastId,
  );

  @override
  Future<List<Rat>> listDeletedCompanyForManagerCursor({
    required String empresaId,
    required int limit,
    DateTime? lastDeletedAt,
    String? lastId,
  }) =>
      _page('manager:$empresaId', lastDeletedAt: lastDeletedAt, lastId: lastId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRatSyncCoordinator implements RatSyncCoordinator {
  RatRestoreSyncResult result = RatRestoreSyncResult.localCompleted;
  Future<RatRestoreSyncResult>? nextResult;
  Object? error;

  @override
  Future<RatRestoreSyncResult> restore({
    required Rat rat,
    required SessaoRemota? session,
  }) async {
    if (error case final Object failure) throw failure;
    if (nextResult != null) return nextResult!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Rat _deletedRat(String id, {DateTime? deletedAt}) {
  final createdAt = DateTime.parse('2026-08-01T10:00:00Z');
  return Rat(
    id: id,
    authorId: 'author-1',
    empresaId: 'empresa-1',
    usuarioId: 'usuario-1',
    tecnicoId: 'tecnico-1',
    ownerType: RatOwnerType.companyTecnico,
    numero: id,
    clienteNome: 'Cliente $id',
    responsavelRecebimento: 'Responsável',
    dataVisita: createdAt,
    horarioInicioAtendimento: '08:00',
    horarioTerminoAtendimento: '09:00',
    descricao: 'Descrição $id',
    status: RatStatus.finalizado,
    syncStatus: RatSyncStatus.synced,
    createdAt: createdAt,
    updatedAt: createdAt,
    deletedAt: deletedAt ?? DateTime.parse('2026-08-09T12:00:00Z'),
  );
}

SessaoRemota _session({
  String empresaId = 'empresa-1',
  SessaoRemotaPapelEmpresa role = SessaoRemotaPapelEmpresa.tecnico,
}) {
  final now = DateTime.now();
  return SessaoRemota(
    id: 'session-1',
    empresaId: empresaId,
    usuarioId: 'usuario-1',
    tecnicoId: 'tecnico-1',
    email: 'user@example.com',
    nome: 'Usuário',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: role,
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

SessaoRemota _appAdminSession() {
  final now = DateTime.now();
  return SessaoRemota(
    id: 'session-app-admin',
    empresaId: null,
    usuarioId: 'app-admin-1',
    tecnicoId: null,
    email: 'admin@example.com',
    nome: 'Admin global',
    mustChangePassword: false,
    papelGlobal: SessaoRemotaPapelGlobal.appAdmin,
    papelEmpresa: null,
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
