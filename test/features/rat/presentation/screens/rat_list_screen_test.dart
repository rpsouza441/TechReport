import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/theme/metric_slate_theme.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/rat/presentation/screens/rat_list_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_view_model.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

void main() {
  late LocalSignatureAssetStore signatureStore;
  late RatPdfShareService pdfService;
  late _StubRatRepository ratRepository;
  late _StubAssinaturaRepository assinaturaRepository;
  late ShareRatLocally shareRatLocally;

  setUp(() {
    assinaturaRepository = _StubAssinaturaRepository();
    pdfService = RatPdfShareService(assinaturaRepository: assinaturaRepository);
    ratRepository = _StubRatRepository([]);
    signatureStore = LocalSignatureAssetStore();
    shareRatLocally = ShareRatLocally(
      ratRepository: ratRepository,
      assinaturaRepository: assinaturaRepository,
    );
  });

  testWidgets('RatListScreen exibe filtros e card de RAT', (tester) async {
    ratRepository.rats = [_sampleRat()];
    final viewModel = RatListViewModel(
      assinaturaRepository: assinaturaRepository,
      ratRepository: ratRepository,
      scope: const RatListScope.local(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MetricSlateTheme.light(),
        home: RatListScreen(
          assinaturaRepository: assinaturaRepository,
          localSignatureAssetStore: signatureStore,
          ratPdfShareService: pdfService,
          viewModel: viewModel,
          ratRepository: ratRepository,
          shareRatLocally: shareRatLocally,
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Relatórios RAT'), findsOneWidget);
    expect(find.text('Buscar cliente ou descrição'), findsOneWidget);
    expect(find.text('Cliente Piloto'), findsOneWidget);
    expect(find.text('Rascunho'), findsWidgets);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Novo RAT'), findsOneWidget);
  });

  testWidgets('RatListScreen mostra estado vazio', (tester) async {
    final viewModel = RatListViewModel(
      assinaturaRepository: assinaturaRepository,
      ratRepository: ratRepository,
      scope: const RatListScope.local(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MetricSlateTheme.light(),
        home: RatListScreen(
          assinaturaRepository: assinaturaRepository,
          localSignatureAssetStore: signatureStore,
          ratPdfShareService: pdfService,
          viewModel: viewModel,
          ratRepository: ratRepository,
          shareRatLocally: shareRatLocally,
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Nenhum RAT cadastrado ainda.'), findsOneWidget);
  });
}

Rat _sampleRat() {
  final now = DateTime(2026, 5, 25);
  return Rat(
    id: 'rat-1',
    authorId: 'auth-1',
    ownerType: RatOwnerType.localTecnico,
    numero: '2026-001',
    clienteNome: 'Cliente Piloto',
    descricao: 'Manutenção preventiva no equipamento.',
    status: RatStatus.draft,
    syncStatus: RatSyncStatus.localOnly,
    createdAt: now,
    updatedAt: now,
  );
}

class _StubRatRepository implements RatRepository {
  _StubRatRepository(this.rats);

  List<Rat> rats;

  @override
  Future<List<Rat>> listLocal() async => rats;

  @override
  Future<List<Rat>> listLocalPage({required int limit, required int offset}) async {
    if (offset >= rats.length) return [];
    return rats.skip(offset).take(limit).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubAssinaturaRepository implements AssinaturaRepository {
  @override
  Future<List<Assinatura>> listByRatId(String ratId) async => [];

  @override
  Future<Uint8List?> readBytes(String id) async => null;

  @override
  Future<void> saveBytes({
    required String assinaturaId,
    required Uint8List bytes,
    required String assetRef,
    required String ratId,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
