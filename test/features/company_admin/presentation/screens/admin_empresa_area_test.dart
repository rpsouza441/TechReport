import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:techreport/features/company_admin/presentation/screens/admin_empresa_area.dart';
import 'package:techreport/features/company_admin/presentation/view_models/admin_empresa_view_model.dart';

void main() {
  late _WidgetRepository repository;

  AdminEmpresaViewModel buildViewModel() {
    return AdminEmpresaViewModel(
      empresaId: 'empresa-1',
      currentTecnicoId: 'admin-1',
      currentPapel: AdminTecnicoPapel.adminEmpresa,
      listTecnicos: ListAdminTecnicos(repository),
      listConvites: ListAdminConvites(repository),
      createTecnicoConvite: CreateTecnicoConvite(repository),
      cancelTecnicoConvite: CancelTecnicoConvite(repository),
      updateTecnicoEquipe: UpdateTecnicoEquipe(repository),
      getAdminEmpresa: GetAdminEmpresa(repository),
      updateAdminEmpresa: UpdateAdminEmpresa(repository),
    );
  }

  Future<void> pumpArea(WidgetTester tester, AdminEmpresaViewModel viewModel) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminEmpresaArea(viewModel: viewModel)),
      ),
    );
  }

  setUp(() {
    repository = _WidgetRepository();
  });

  testWidgets('troca loading inicial pela equipe apos notificacao', (
    tester,
  ) async {
    repository.loadGate = Completer<void>();
    repository.tecnicos = [_tecnico()];
    final viewModel = buildViewModel();

    await pumpArea(tester, viewModel);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Tecnico Teste'), findsNothing);

    repository.loadGate!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Tecnico Teste'), findsOneWidget);
    expect(find.text('Inativar'), findsOneWidget);
  });

  testWidgets('troca loading inicial pelo estado vazio', (tester) async {
    repository.loadGate = Completer<void>();
    final viewModel = buildViewModel();

    await pumpArea(tester, viewModel);
    repository.loadGate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Equipe vazia'), findsOneWidget);
  });

  testWidgets('troca loading inicial por erro', (tester) async {
    repository.loadGate = Completer<void>();
    repository.loadError = Exception('falha de consulta');
    final viewModel = buildViewModel();

    await pumpArea(tester, viewModel);
    repository.loadGate!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('falha de consulta'), findsOneWidget);
  });

  testWidgets('atualizar recupera a tela depois de falha de rede', (
    tester,
  ) async {
    repository.loadError = Exception('Network is unreachable');
    final viewModel = buildViewModel();
    await pumpArea(tester, viewModel);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem conexão com o servidor'), findsOneWidget);

    repository.loadError = null;
    repository.tecnicos = [_tecnico()];
    await tester.tap(find.byTooltip('Atualizar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sem conexão com o servidor'), findsNothing);
    expect(find.text('Tecnico Teste'), findsOneWidget);
  });

  testWidgets('inativacao atualiza o chip na mesma tela', (tester) async {
    repository.tecnicos = [_tecnico()];
    final viewModel = buildViewModel();
    await pumpArea(tester, viewModel);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inativar'));
    await tester.pumpAndSettle();

    expect(repository.updatedAtivo, isFalse);
    expect(find.text('Ativar'), findsOneWidget);
    expect(find.text('Inativar'), findsNothing);
  });

  testWidgets('acoes ficam desabilitadas durante alteracao', (tester) async {
    repository.tecnicos = [_tecnico()];
    repository.updateGate = Completer<void>();
    final viewModel = buildViewModel();
    await pumpArea(tester, viewModel);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inativar'));
    await tester.pump();

    final chip = tester.widget<ActionChip>(
      find.ancestor(
        of: find.text('Inativar'),
        matching: find.byType(ActionChip),
      ),
    );
    expect(chip.onPressed, isNull);

    repository.updateGate!.complete();
    await tester.pumpAndSettle();
  });
}

AdminTecnicoResumo _tecnico({bool ativo = true}) {
  return AdminTecnicoResumo(
    id: 'tecnico-1',
    empresaId: 'empresa-1',
    nome: 'Tecnico Teste',
    email: 'tecnico@example.com',
    papel: AdminTecnicoPapel.tecnico,
    ativo: ativo,
  );
}

class _WidgetRepository implements CompanyAdminRepository {
  List<AdminTecnicoResumo> tecnicos = [];
  Completer<void>? loadGate;
  Completer<void>? updateGate;
  Object? loadError;
  bool? updatedAtivo;

  Future<void> _waitForLoad() async {
    await loadGate?.future;
    if (loadError case final error?) throw error;
  }

  @override
  Future<AdminEmpresaResumo> getEmpresa(String empresaId) async {
    await _waitForLoad();
    return const AdminEmpresaResumo(
      id: 'empresa-1',
      nome: 'Empresa Teste',
      ativo: true,
    );
  }

  @override
  Future<List<AdminTecnicoResumo>> listTecnicos({
    required String empresaId,
  }) async {
    await _waitForLoad();
    return List.of(tecnicos);
  }

  @override
  Future<List<AdminConviteResumo>> listConvites({
    required String empresaId,
  }) async {
    await _waitForLoad();
    return [];
  }

  @override
  Future<void> updateTecnicoEquipe({
    required String tecnicoId,
    bool? ativo,
    bool? mustChangePassword,
  }) async {
    await updateGate?.future;
    updatedAtivo = ativo;
    tecnicos = [
      for (final tecnico in tecnicos)
        AdminTecnicoResumo(
          id: tecnico.id,
          empresaId: tecnico.empresaId,
          nome: tecnico.nome,
          email: tecnico.email,
          papel: tecnico.papel,
          ativo: ativo ?? tecnico.ativo,
          mustChangePassword: mustChangePassword ?? tecnico.mustChangePassword,
        ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
