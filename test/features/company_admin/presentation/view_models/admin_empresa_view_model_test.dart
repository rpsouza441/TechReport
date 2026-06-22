import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/repositories/company_admin_repository.dart';
import 'package:techreport/features/company_admin/domain/usecases/cancel_tecnico_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/create_tecnico_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/get_admin_empresa.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_convites.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_admin_tecnicos.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_admin_empresa.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_tecnico_equipe.dart';
import 'package:techreport/features/company_admin/presentation/view_models/admin_empresa_view_model.dart';

void main() {
  late _StubCompanyAdminRepository repository;

  AdminEmpresaViewModel buildViewModel({
    AdminTecnicoPapel papel = AdminTecnicoPapel.adminEmpresa,
    String? currentTecnicoId = 'admin-1',
  }) {
    return AdminEmpresaViewModel(
      empresaId: 'empresa-1',
      currentTecnicoId: currentTecnicoId,
      currentPapel: papel,
      listTecnicos: ListAdminTecnicos(repository),
      listConvites: ListAdminConvites(repository),
      createTecnicoConvite: CreateTecnicoConvite(repository),
      cancelTecnicoConvite: CancelTecnicoConvite(repository),
      updateTecnicoEquipe: UpdateTecnicoEquipe(repository),
      getAdminEmpresa: GetAdminEmpresa(repository),
      updateAdminEmpresa: UpdateAdminEmpresa(repository),
    );
  }

  setUp(() {
    repository = _StubCompanyAdminRepository();
  });

  test('load publica loading e preenche todos os dados', () async {
    repository.tecnicos = [_tecnico()];
    repository.convites = [_convite()];
    final viewModel = buildViewModel();
    final loadingStates = <bool>[];
    viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

    await viewModel.load();

    expect(loadingStates, [true, false]);
    expect(viewModel.empresa?.nome, 'Empresa Teste');
    expect(viewModel.tecnicos, hasLength(1));
    expect(viewModel.convites, hasLength(1));
    expect(viewModel.errorMessage, isNull);
  });

  test('load limpa loading e publica erro quando uma consulta falha', () async {
    repository.loadError = Exception('falha de consulta');
    final viewModel = buildViewModel();

    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, 'falha de consulta');
  });

  test('load converte falha de rede em mensagem amigavel', () async {
    repository.loadError = Exception(
      'AuthRetryableFetchException(message: ClientException with '
      'SocketConnection failed: Network is unreachable)',
    );
    final viewModel = buildViewModel();

    await viewModel.load();

    expect(
      viewModel.errorMessage,
      'Sem conexão com o servidor. Verifique sua conexão e tente novamente.',
    );
  });

  test('nova carga bem-sucedida limpa erro anterior', () async {
    repository.loadError = Exception('falha temporaria');
    final viewModel = buildViewModel();
    await viewModel.load();
    repository.loadError = null;

    await viewModel.load();

    expect(viewModel.errorMessage, isNull);
    expect(viewModel.empresa, isNotNull);
  });

  test('setTecnicoAtivo atualiza, recarrega e limpa submitting', () async {
    repository.tecnicos = [_tecnico()];
    final viewModel = buildViewModel();
    await viewModel.load();

    final result = await viewModel.setTecnicoAtivo(
      tecnico: repository.tecnicos.single,
      ativo: false,
    );

    expect(result, isTrue);
    expect(repository.updatedTecnicoId, 'tecnico-1');
    expect(repository.updatedAtivo, isFalse);
    expect(repository.listTecnicosCalls, 2);
    expect(viewModel.tecnicos.single.ativo, isFalse);
    expect(viewModel.isSubmitting, isFalse);
  });

  test('setTecnicoAtivo limpa submitting quando atualizacao falha', () async {
    final viewModel = buildViewModel();
    final tecnico = _tecnico();
    repository.updateError = Exception('falha ao atualizar');

    final result = await viewModel.setTecnicoAtivo(
      tecnico: tecnico,
      ativo: false,
    );

    expect(result, isFalse);
    expect(viewModel.isSubmitting, isFalse);
    expect(viewModel.errorMessage, 'falha ao atualizar');
  });

  test('setTecnicoAtivo nao executa sem permissao', () async {
    final tecnico = _tecnico(id: 'admin-1');
    final viewModel = buildViewModel(currentTecnicoId: tecnico.id);

    final result = await viewModel.setTecnicoAtivo(
      tecnico: tecnico,
      ativo: false,
    );

    expect(result, isFalse);
    expect(repository.updateTecnicoCalls, 0);
    expect(viewModel.isSubmitting, isFalse);
  });
}

AdminTecnicoResumo _tecnico({String id = 'tecnico-1', bool ativo = true}) {
  return AdminTecnicoResumo(
    id: id,
    empresaId: 'empresa-1',
    nome: 'Tecnico Teste',
    email: 'tecnico@example.com',
    papel: AdminTecnicoPapel.tecnico,
    ativo: ativo,
  );
}

AdminConviteResumo _convite() {
  final now = DateTime.now();
  return AdminConviteResumo(
    id: 'convite-1',
    empresaId: 'empresa-1',
    email: 'convite@example.com',
    nome: 'Convidado',
    papel: AdminTecnicoPapel.tecnico,
    status: AdminConviteStatus.pending,
    expiresAt: now.add(const Duration(days: 1)),
    createdAt: now,
  );
}

class _StubCompanyAdminRepository implements CompanyAdminRepository {
  AdminEmpresaResumo empresa = const AdminEmpresaResumo(
    id: 'empresa-1',
    nome: 'Empresa Teste',
    ativo: true,
  );
  List<AdminTecnicoResumo> tecnicos = [];
  List<AdminConviteResumo> convites = [];
  Object? loadError;
  Object? updateError;
  int listTecnicosCalls = 0;
  int updateTecnicoCalls = 0;
  String? updatedTecnicoId;
  bool? updatedAtivo;

  @override
  Future<AdminEmpresaResumo> getEmpresa(String empresaId) async {
    if (loadError case final error?) throw error;
    return empresa;
  }

  @override
  Future<List<AdminTecnicoResumo>> listTecnicos({
    required String empresaId,
  }) async {
    listTecnicosCalls++;
    if (loadError case final error?) throw error;
    return List.of(tecnicos);
  }

  @override
  Future<List<AdminConviteResumo>> listConvites({
    required String empresaId,
  }) async {
    if (loadError case final error?) throw error;
    return List.of(convites);
  }

  @override
  Future<void> updateTecnicoEquipe({
    required String tecnicoId,
    bool? ativo,
    bool? mustChangePassword,
  }) async {
    updateTecnicoCalls++;
    if (updateError case final error?) throw error;
    updatedTecnicoId = tecnicoId;
    updatedAtivo = ativo;
    tecnicos = [
      for (final tecnico in tecnicos)
        if (tecnico.id == tecnicoId)
          AdminTecnicoResumo(
            id: tecnico.id,
            empresaId: tecnico.empresaId,
            nome: tecnico.nome,
            email: tecnico.email,
            papel: tecnico.papel,
            ativo: ativo ?? tecnico.ativo,
            mustChangePassword:
                mustChangePassword ?? tecnico.mustChangePassword,
          )
        else
          tecnico,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
