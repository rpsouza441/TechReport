import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/presentation/widgets/rat_list_item_card.dart';

void main() {
  final fixtureRat = Rat(
    id: 'rat-1',
    authorId: 'author-1',
    ownerType: RatOwnerType.localTecnico,
    numero: 'RAT-2024-001',
    clienteNome: 'Acme Corp',
    descricao: 'Manutenção preventiva',
    status: RatStatus.finalizado,
    syncStatus: RatSyncStatus.synced,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 6, 15),
  );

  Widget buildCard({
    required Rat rat,
    bool hasSignature = false,
    bool showSyncStatus = true,
    DateTime? trailingDate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RatListItemCard(
          rat: rat,
          hasSignature: hasSignature,
          onTap: () {},
          onPreviewPdf: () {},
          showSyncStatus: showSyncStatus,
          trailingDate: trailingDate,
        ),
      ),
    );
  }

  group('RatListItemCard', () {
    testWidgets('exibe nome do cliente e numero do RAT', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildCard(rat: fixtureRat));

      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('RAT-2024-001'), findsOneWidget);
    });

    testWidgets('exibe descricao do RAT', (WidgetTester tester) async {
      await tester.pumpWidget(buildCard(rat: fixtureRat));

      expect(find.text('Manutenção preventiva'), findsOneWidget);
    });

    testWidgets('exibe icone de assinatura quando hasSignature=true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildCard(rat: fixtureRat, hasSignature: true));

      expect(find.byIcon(Icons.draw), findsOneWidget);
      expect(find.byTooltip('Assinatura capturada'), findsOneWidget);
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byIcon(Icons.draw),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('exibe icone pendente quando hasSignature=false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildCard(rat: fixtureRat, hasSignature: false));

      expect(find.byIcon(Icons.draw_outlined), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message?.startsWith('Assinatura n') == true &&
              widget.message?.endsWith('capturada') == true,
        ),
        findsOneWidget,
      );
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byIcon(Icons.draw_outlined),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.4);
    });

    testWidgets('exibe chip de sync quando showSyncStatus=true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildCard(rat: fixtureRat, showSyncStatus: true));

      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets('NAO exibe chip de sync quando showSyncStatus=false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildCard(rat: fixtureRat, showSyncStatus: false),
      );

      expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    });

    testWidgets('exibe data formatada quando trailingDate!=null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildCard(
          rat: fixtureRat,
          showSyncStatus: false,
          trailingDate: DateTime(2024, 6, 15),
        ),
      );

      expect(find.text('15/06/2024'), findsOneWidget);
    });

    testWidgets('NAO exibe data quando trailingDate=null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildCard(rat: fixtureRat, showSyncStatus: false, trailingDate: null),
      );

      expect(find.text('15/06/2024'), findsNothing);
    });

    testWidgets('dispara onTap ao tocar no card', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatListItemCard(
              rat: fixtureRat,
              hasSignature: false,
              onTap: () => tapped = true,
              onPreviewPdf: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('dispara onPreviewPdf ao tocar no botao PDF', (
      WidgetTester tester,
    ) async {
      var pdfTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatListItemCard(
              rat: fixtureRat,
              hasSignature: false,
              onTap: () {},
              onPreviewPdf: () => pdfTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
      expect(pdfTapped, isTrue);
    });
  });
}
