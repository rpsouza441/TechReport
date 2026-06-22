import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
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
  }) {
    return RatFormViewModel(
      assinaturaRepository: _StubAssinaturaRepository(signatures),
      localSignatureAssetStore: _StubLocalSignatureAssetStore(),
      ratPdfShareService: _StubRatPdfShareService(),
      ratRepository: _StubRatRepository(),
      shareRatLocally: _StubShareRatLocally(),
      initialRat: initialRat,
      remoteSession: remoteSession,
    );
  }

  Future<void> pumpForm(WidgetTester tester, RatFormViewModel viewModel) async {
    await tester.pumpWidget(
      MaterialApp(home: RatFormScreen(viewModel: viewModel)),
    );
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

SessaoRemota _session({required String tecnicoId}) {
  final now = DateTime.now();
  return SessaoRemota(
    id: 'sessao-1',
    empresaId: 'empresa-1',
    usuarioId: 'usuario-1',
    tecnicoId: tecnicoId,
    email: 'tecnico@example.com',
    nome: 'Tecnico',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: SessaoRemotaPapelEmpresa.tecnico,
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
}

class _StubShareRatLocally implements ShareRatLocally {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
