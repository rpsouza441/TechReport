import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/theme/metric_slate_theme.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/services/rat_sync_coordinator.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/rat/presentation/screens/rat_form_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_form_view_model.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

void main() {
  RatFormViewModel buildViewModel({
    Rat? initialRat,
    SessaoRemota? remoteSession,
    List<Assinatura> signatures = const [],
    _StubRatRepository? ratRepository,
    _StubRatSyncCoordinator? syncCoordinator,
    String? ownerDisplayName,
  }) {
    return RatFormViewModel(
      assinaturaRepository: _StubAssinaturaRepository(signatures),
      localSignatureAssetStore: _StubLocalSignatureAssetStore(),
      ratPdfShareService: _StubRatPdfShareService(),
      ratRepository: ratRepository ?? _StubRatRepository(),
      shareRatLocally: _StubShareRatLocally(),
      initialRat: initialRat,
      remoteSession: remoteSession,
      syncCoordinator: syncCoordinator,
      ownerDisplayName: ownerDisplayName,
    );
  }

  Future<void> pumpForm(
    WidgetTester tester,
    RatFormViewModel viewModel, {
    WidgetBuilder? auditScreenBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MetricSlateTheme.light(),
        home: RatFormScreen(
          viewModel: viewModel,
          auditScreenBuilder: auditScreenBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpRoutedForm(
    WidgetTester tester,
    RatFormViewModel viewModel, {
    WidgetBuilder? auditScreenBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MetricSlateTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RatFormScreen(
                      viewModel: viewModel,
                      auditScreenBuilder: auditScreenBuilder,
                    ),
                  ),
                ),
                child: const Text('Abrir formulário'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir formulário'));
    await tester.pumpAndSettle();
  }

  testWidgets('data escolhida aparece imediatamente no formulario', (
    tester,
  ) async {
    final viewModel = buildViewModel();
    addTearDown(viewModel.dispose);
    await pumpForm(tester, viewModel);
    final now = DateTime.now();

    await tester.tap(find.text('Selecione'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final expected = '15/${now.month.toString().padLeft(2, '0')}/${now.year}';
    expect(find.text(expected), findsOneWidget);
    expect(viewModel.dataVisita, DateTime(now.year, now.month, 15));
  });

  testWidgets('cancelar calendario preserva data existente', (tester) async {
    final initialDate = DateTime(2026, 6, 20);
    final viewModel = buildViewModel(initialRat: _rat(dataVisita: initialDate));
    addTearDown(viewModel.dispose);
    await pumpForm(tester, viewModel);

    await tester.tap(find.text('20/06/2026'));
    await tester.pumpAndSettle();
    final dialogContext = tester.element(find.byType(DatePickerDialog));
    Navigator.of(dialogContext).pop();
    await tester.pumpAndSettle();

    expect(find.text('20/06/2026'), findsOneWidget);
    expect(viewModel.dataVisita, initialDate);
  });

  testWidgets('nova selecao substitui data existente', (tester) async {
    final viewModel = buildViewModel(
      initialRat: _rat(dataVisita: DateTime(2026, 6, 20)),
    );
    addTearDown(viewModel.dispose);
    await pumpForm(tester, viewModel);

    await tester.tap(find.text('20/06/2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('15/06/2026'), findsOneWidget);
    expect(find.text('20/06/2026'), findsNothing);
    expect(viewModel.dataVisita, DateTime(2026, 6, 15));
  });

  testWidgets('campo somente leitura nao abre calendario', (tester) async {
    final initialDate = DateTime(2026, 6, 20);
    final viewModel = buildViewModel(
      initialRat: _rat(dataVisita: initialDate, tecnicoId: 'outro-tecnico'),
      remoteSession: _session(tecnicoId: 'tecnico-atual'),
    );
    addTearDown(viewModel.dispose);
    await pumpForm(tester, viewModel);

    await tester.tap(find.text('20/06/2026'));
    await tester.pump();

    expect(find.byType(DatePickerDialog), findsNothing);
    expect(viewModel.dataVisita, initialDate);
  });

  testWidgets('mostra reabertura para tecnico proprietario apos assinatura', (
    tester,
  ) async {
    final rat = _rat(
      dataVisita: DateTime(2026, 6, 20),
      status: RatStatus.finalizado,
    );
    final viewModel = buildViewModel(
      initialRat: rat,
      remoteSession: _session(tecnicoId: 'tecnico-atual'),
      signatures: [_signature(rat.id)],
    );
    addTearDown(viewModel.dispose);
    await pumpForm(tester, viewModel);

    expect(find.text('Correção'), findsOneWidget);
    expect(find.text('Reabrir para correção'), findsOneWidget);
  });

  testWidgets('nao mostra reabertura antes da assinatura', (tester) async {
    final viewModel = buildViewModel(
      initialRat: _rat(
        dataVisita: DateTime(2026, 6, 20),
        status: RatStatus.finalizado,
      ),
      remoteSession: _session(tecnicoId: 'tecnico-atual'),
    );
    addTearDown(viewModel.dispose);
    await pumpForm(tester, viewModel);

    expect(find.text('Correção'), findsNothing);
    expect(find.text('Reabrir para correção'), findsNothing);
  });

  testWidgets('nao mostra reabertura para outro tecnico', (tester) async {
    final rat = _rat(
      dataVisita: DateTime(2026, 6, 20),
      tecnicoId: 'outro-tecnico',
      status: RatStatus.finalizado,
    );
    final viewModel = buildViewModel(
      initialRat: rat,
      remoteSession: _session(tecnicoId: 'tecnico-atual'),
      signatures: [_signature(rat.id)],
    );
    addTearDown(viewModel.dispose);
    await pumpForm(tester, viewModel);

    expect(find.text('Correção'), findsNothing);
    expect(find.text('Reabrir para correção'), findsNothing);
  });
  group('correção de RAT de terceiro', () {
    testWidgets('superior vê atribuição, proprietário imutável e histórico', (
      tester,
    ) async {
      final viewModel = buildViewModel(
        initialRat: _rat(
          dataVisita: DateTime(2026, 6, 20),
          tecnicoId: 'tecnico-proprietario',
        ),
        remoteSession: _session(
          tecnicoId: 'gerente-1',
          role: SessaoRemotaPapelEmpresa.gerente,
        ),
        ownerDisplayName: 'Ana Técnica',
      );
      addTearDown(viewModel.dispose);
      await pumpForm(
        tester,
        viewModel,
        auditScreenBuilder: (_) =>
            const Scaffold(body: Text('Histórico carregado')),
      );

      expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
      expect(find.text('Corrigindo RAT de Ana Técnica'), findsOneWidget);
      expect(
        find.text(
          'A RAT continuará pertencendo a Ana Técnica. Suas alterações serão registradas no histórico.',
        ),
        findsOneWidget,
      );
      expect(find.text('Proprietário'), findsOneWidget);
      expect(find.text('Ana Técnica'), findsOneWidget);
      expect(find.byTooltip('Ver histórico da RAT'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Corrigindo RAT de Ana Técnica')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Ver histórico da RAT'));
      await tester.pumpAndSettle();
      expect(find.text('Histórico carregado'), findsOneWidget);
    });

    testWidgets('proprietário não vê banner de correção por terceiro', (
      tester,
    ) async {
      final viewModel = buildViewModel(
        initialRat: _rat(dataVisita: DateTime(2026, 6, 20)),
        remoteSession: _session(tecnicoId: 'tecnico-atual'),
        ownerDisplayName: 'Técnico atual',
      );
      addTearDown(viewModel.dispose);
      await pumpForm(tester, viewModel);

      expect(find.byIcon(Icons.edit_note_outlined), findsNothing);
      expect(find.textContaining('Corrigindo RAT de'), findsNothing);
    });

    testWidgets('técnico não dono, app_admin e cross-company não mutam RAT', (
      tester,
    ) async {
      final forbiddenSessions = [
        _session(tecnicoId: 'outro-tecnico'),
        _appAdminSession(),
        _session(
          tecnicoId: 'gerente-1',
          empresaId: 'outra-empresa',
          role: SessaoRemotaPapelEmpresa.gerente,
        ),
      ];

      for (final session in forbiddenSessions) {
        final repository = _StubRatRepository();
        final viewModel = buildViewModel(
          initialRat: _rat(dataVisita: DateTime(2026, 6, 20)),
          remoteSession: session,
          ratRepository: repository,
          ownerDisplayName: 'Técnico atual',
        );
        addTearDown(viewModel.dispose);
        await pumpForm(tester, viewModel);

        expect(find.byTooltip('Ver histórico da RAT'), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
        final save = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Salvar alterações'),
        );
        expect(save.onPressed, isNull);
        expect(repository.savedRats, isEmpty);
      }
    });

    testWidgets('perda de permissão preserva controllers e desabilita salvar', (
      tester,
    ) async {
      final viewModel = buildViewModel(
        initialRat: _rat(
          dataVisita: DateTime(2026, 6, 20),
          tecnicoId: 'tecnico-proprietario',
        ),
        remoteSession: _session(
          tecnicoId: 'gerente-1',
          role: SessaoRemotaPapelEmpresa.gerente,
        ),
        ownerDisplayName: 'Ana Técnica',
      );
      addTearDown(viewModel.dispose);
      await pumpForm(tester, viewModel);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cliente'),
        'Texto ainda não salvo',
      );
      viewModel.updateRemoteSession(
        _session(
          tecnicoId: 'gerente-1',
          empresaId: 'outra-empresa',
          role: SessaoRemotaPapelEmpresa.gerente,
        ),
      );
      await tester.pump();

      expect(find.text('Texto ainda não salvo'), findsOneWidget);
      expect(
        find.text(
          'Sua permissão para editar esta RAT mudou. Copie o que precisar e volte para a lista.',
        ),
        findsOneWidget,
      );
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Salvar alterações'),
      );
      expect(save.onPressed, isNull);
    });
  });

  group('mover para a lixeira', () {
    testWidgets('confirmação usa copy segura e foco inicial em Manter RAT', (
      tester,
    ) async {
      final viewModel = buildViewModel(
        initialRat: _rat(dataVisita: DateTime(2026, 6, 20)),
        remoteSession: _session(tecnicoId: 'tecnico-atual'),
      );
      addTearDown(viewModel.dispose);
      await pumpForm(tester, viewModel);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Mover RAT para a lixeira?'), findsOneWidget);
      expect(
        find.text(
          'A RAT sairá da lista principal e poderá ser restaurada depois. Nenhum dado será apagado permanentemente.',
        ),
        findsOneWidget,
      );
      expect(find.text('Manter RAT'), findsOneWidget);
      expect(find.text('Mover para a lixeira'), findsOneWidget);
      expect(find.text('Excluir permanentemente'), findsNothing);
      expect(
        Focus.of(tester.element(find.text('Manter RAT'))).hasFocus,
        isTrue,
      );
    });

    testWidgets('sucesso sai do formulário e anuncia lixeira', (tester) async {
      final repository = _StubRatRepository();
      final coordinator = _StubRatSyncCoordinator();
      final viewModel = buildViewModel(
        initialRat: _rat(dataVisita: DateTime(2026, 6, 20)),
        remoteSession: _session(tecnicoId: 'tecnico-atual'),
        ratRepository: repository,
        syncCoordinator: coordinator,
      );
      addTearDown(viewModel.dispose);
      await pumpRoutedForm(tester, viewModel);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mover para a lixeira'));
      await tester.pumpAndSettle();

      expect(find.text('Abrir formulário'), findsOneWidget);
      expect(find.text('RAT movida para a lixeira.'), findsOneWidget);
      expect(repository.savedRats.single.deletedAt, isNotNull);
    });
  });

  group('feedback de correção', () {
    testWidgets('correção online usa snackbar aprovada e preserva dono', (
      tester,
    ) async {
      final repository = _StubRatRepository();
      final viewModel = buildViewModel(
        initialRat: _rat(
          dataVisita: DateTime(2026, 6, 20),
          tecnicoId: 'tecnico-proprietario',
        ),
        remoteSession: _session(
          tecnicoId: 'gerente-1',
          role: SessaoRemotaPapelEmpresa.gerente,
        ),
        ratRepository: repository,
        syncCoordinator: _StubRatSyncCoordinator(),
        ownerDisplayName: 'Ana Técnica',
      );
      addTearDown(viewModel.dispose);
      await pumpRoutedForm(tester, viewModel);

      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();

      expect(
        find.text('Alterações salvas e registradas no histórico.'),
        findsOneWidget,
      );
      expect(repository.savedRats.single.tecnicoId, 'tecnico-proprietario');
      expect(repository.savedRats.single.empresaId, 'empresa-1');
      expect(repository.savedRats.single.usuarioId, 'usuario-1');
    });

    testWidgets('correção offline informa fila sem perder alteração local', (
      tester,
    ) async {
      final repository = _StubRatRepository();
      final coordinator = _StubRatSyncCoordinator()..offline = true;
      final viewModel = buildViewModel(
        initialRat: _rat(
          dataVisita: DateTime(2026, 6, 20),
          tecnicoId: 'tecnico-proprietario',
        ),
        remoteSession: _session(
          tecnicoId: 'gerente-1',
          role: SessaoRemotaPapelEmpresa.gerente,
        ),
        ratRepository: repository,
        syncCoordinator: coordinator,
        ownerDisplayName: 'Ana Técnica',
      );
      addTearDown(viewModel.dispose);
      await pumpRoutedForm(tester, viewModel);

      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Alterações salvas neste dispositivo. O histórico será atualizado após a sincronização.',
        ),
        findsOneWidget,
      );
      expect(repository.savedRats, hasLength(1));
    });
  });
}

Assinatura _signature(String ratId) {
  final now = DateTime(2026, 6, 20);
  return Assinatura(
    id: 'assinatura-$ratId',
    ratId: ratId,
    storageMode: StorageMode.inlineBinary,
    assetRef: 'signatures/assinatura-$ratId.png',
    data: Uint8List.fromList([1, 2, 3]),
    sizeBytes: 3,
    mimeType: 'image/png',
    createdAt: now,
    updatedAt: now,
  );
}

Rat _rat({
  required DateTime dataVisita,
  String tecnicoId = 'tecnico-atual',
  RatStatus status = RatStatus.draft,
}) {
  return Rat(
    id: 'rat-1',
    authorId: 'author-1',
    empresaId: 'empresa-1',
    usuarioId: 'usuario-1',
    tecnicoId: tecnicoId,
    ownerType: RatOwnerType.companyTecnico,
    numero: '0001',
    clienteNome: 'Cliente Teste',
    responsavelRecebimento: 'Responsavel',
    dataVisita: dataVisita,
    horarioInicioAtendimento: '0800',
    horarioTerminoAtendimento: '1000',
    descricao: 'Descricao',
    status: status,
    syncStatus: RatSyncStatus.localOnly,
    createdAt: DateTime(2026, 6, 20),
    updatedAt: DateTime(2026, 6, 20),
  );
}

SessaoRemota _session({
  required String tecnicoId,
  String empresaId = 'empresa-1',
  SessaoRemotaPapelEmpresa role = SessaoRemotaPapelEmpresa.tecnico,
}) {
  final now = DateTime.now();
  return SessaoRemota(
    id: 'sessao-1',
    empresaId: empresaId,
    usuarioId: 'usuario-1',
    tecnicoId: tecnicoId,
    email: 'tecnico@example.com',
    nome: 'Tecnico',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: role,
    accessTokenRef: 'access-token',
    refreshTokenRef: 'refresh-token',
    endpointRef: 'https://api.example.com',
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
    id: 'sessao-app-admin',
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
    endpointRef: 'https://api.example.com',
    expiresAt: now.add(const Duration(hours: 1)),
    lastValidatedAt: now,
    offlineAccessUntil: now.add(const Duration(days: 7)),
    createdAt: now,
    updatedAt: now,
  );
}

class _StubAssinaturaRepository implements AssinaturaRepository {
  _StubAssinaturaRepository(this.signatures);

  final List<Assinatura> signatures;

  @override
  Future<List<Assinatura>> listByRatId(String ratId) async =>
      signatures.where((signature) => signature.ratId == ratId).toList();

  @override
  Future<Uint8List?> readBytes(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubLocalSignatureAssetStore implements LocalSignatureAssetStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubRatPdfShareService implements RatPdfShareService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubRatRepository implements RatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final List<Rat> savedRats = [];

  @override
  Future<void> save(Rat rat) async {
    savedRats.add(rat);
  }

  @override
  Future<void> update(Rat rat) async {
    savedRats.add(rat);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubRatSyncCoordinator implements RatSyncCoordinator {
  bool offline = false;

  @override
  Future<void> syncAfterSave({
    required Rat rat,
    required String empresaId,
    required String usuarioId,
  }) async {
    if (offline) throw const SocketException('sem conexão');
  }

  @override
  Future<void> syncAfterDelete({
    required Rat rat,
    required String empresaId,
    required String usuarioId,
  }) async {
    if (offline) throw const SocketException('sem conexão');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubShareRatLocally implements ShareRatLocally {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
