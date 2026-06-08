import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/theme/metric_slate_theme.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_info_row.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_section_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: MetricSlateTheme.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('TechReportCard warning usa errorContainer', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TechReportCard(
          tone: TechReportCardTone.warning,
          child: Text('Aviso'),
        ),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(TechReportCard),
        matching: find.byType(DecoratedBox),
      ),
    );
    final theme = MetricSlateTheme.light();

    expect(
      (decorated.decoration as BoxDecoration).color,
      theme.colorScheme.errorContainer,
    );
  });

  testWidgets('TechReportInfoRow exibe label e valor', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TechReportInfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: 'a@b.com',
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('a@b.com'), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
  });

  testWidgets('TechReportStatusChip mostra contagem', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TechReportStatusChip(
          label: 'Pendentes',
          count: 3,
          tone: TechReportStatusTone.warning,
        ),
      ),
    );

    expect(find.text('Pendentes: 3'), findsOneWidget);
  });

  testWidgets('TechReportFormHeader mostra titulo', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TechReportFormHeader(
          icon: Icons.dns_outlined,
          title: 'Servidor',
          subtitle: 'Configure a URL',
        ),
      ),
    );

    expect(find.text('Servidor'), findsOneWidget);
    expect(find.text('Configure a URL'), findsOneWidget);
  });

  testWidgets('TechReportErrorBanner mostra mensagem', (tester) async {
    await tester.pumpWidget(
      wrap(const TechReportErrorBanner(message: 'Falha ao salvar')),
    );

    expect(find.text('Falha ao salvar'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('TechReportSectionHeader mostra titulo e trailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const TechReportSectionHeader(
          title: 'Pendentes',
          trailing: Icon(Icons.more_horiz),
        ),
      ),
    );

    expect(find.text('Pendentes'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });
}
