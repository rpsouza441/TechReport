import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/theme/metric_slate_theme.dart';

void main() {
  group('MetricSlateTheme etapa 2', () {
    late ThemeData theme;

    setUp(() {
      theme = MetricSlateTheme.light();
    });

    test('expoe themes globais de componentes Material', () {
      expect(theme.textTheme.titleLarge, isNotNull);
      expect(theme.textTheme.bodyMedium, isNotNull);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.cardTheme, isNotNull);
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(
        theme.inputDecorationTheme.constraints?.minHeight,
        48,
      );
      expect(theme.filledButtonTheme.style, isNotNull);
      expect(theme.outlinedButtonTheme.style, isNotNull);
      expect(theme.textButtonTheme.style, isNotNull);
      expect(theme.navigationBarTheme.height, 72);
      expect(theme.navigationBarTheme.indicatorShape, isNotNull);
      expect(theme.dialogTheme, isNotNull);
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(theme.chipTheme, isNotNull);
      expect(theme.floatingActionButtonTheme, isNotNull);
      expect(theme.bottomSheetTheme, isNotNull);
      expect(theme.listTileTheme, isNotNull);
    });

    test('FilledButton disabled usa cor atenuada', () {
      final style = theme.filledButtonTheme.style!;
      final disabledBg = style.backgroundColor?.resolve({WidgetState.disabled});
      final enabledBg = style.backgroundColor?.resolve(<WidgetState>{});

      expect(disabledBg, isNotNull);
      expect(enabledBg, const Color(0xFF1E40AF));
      expect(disabledBg, isNot(equals(enabledBg)));
    });

    test('NavigationBar selecionado destaca label e icone', () {
      final nav = theme.navigationBarTheme;
      final selectedLabel = nav.labelTextStyle?.resolve({WidgetState.selected});
      final idleLabel = nav.labelTextStyle?.resolve(<WidgetState>{});

      expect(selectedLabel?.fontWeight, FontWeight.w700);
      expect(idleLabel?.fontWeight, FontWeight.w500);
      expect(selectedLabel?.color, isNot(equals(idleLabel?.color)));
    });
  });
}
