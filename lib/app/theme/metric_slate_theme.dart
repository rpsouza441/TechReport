import 'package:flutter/material.dart';

import 'metric_slate_colors.dart';
import 'metric_slate_component_themes.dart';

class MetricSlateTheme {
  const MetricSlateTheme._();

  static const defaultFamily = MetricSlateColors.defaultFamily;
  static const defaultBrightness = MetricSlateColors.defaultBrightness;

  static ThemeData light({MetricSlateThemeFamily family = defaultFamily}) {
    return _build(
      MetricSlateColors.paletteFor(
        family: family,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData dark({MetricSlateThemeFamily family = defaultFamily}) {
    return _build(
      MetricSlateColors.paletteFor(family: family, brightness: Brightness.dark),
    );
  }

  /// Atalho para preview ou testes manuais de tema.
  static ThemeData test({
    MetricSlateThemeFamily family = defaultFamily,
    Brightness brightness = defaultBrightness,
  }) {
    return _build(
      MetricSlateColors.paletteFor(family: family, brightness: brightness),
    );
  }

  static ThemeData forPalette(MetricSlatePalette palette) {
    return _build(palette);
  }

  static ThemeData _build(MetricSlatePalette palette) {
    final colorScheme = MetricSlateComponentThemes.colorScheme(palette);
    final textTheme = MetricSlateComponentThemes.textTheme(palette);

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: palette.onSurface, size: 24),
      appBarTheme: MetricSlateComponentThemes.appBar(palette, textTheme),
      cardTheme: MetricSlateComponentThemes.card(palette),
      inputDecorationTheme: MetricSlateComponentThemes.input(palette),
      filledButtonTheme: MetricSlateComponentThemes.filledButton(
        palette,
        textTheme,
      ),
      outlinedButtonTheme: MetricSlateComponentThemes.outlinedButton(
        palette,
        textTheme,
      ),
      textButtonTheme: MetricSlateComponentThemes.textButton(
        palette,
        textTheme,
      ),
      floatingActionButtonTheme: MetricSlateComponentThemes.fab(palette),
      navigationBarTheme: MetricSlateComponentThemes.navigationBar(
        palette,
        textTheme,
      ),
      chipTheme: MetricSlateComponentThemes.chip(palette, textTheme),
      dialogTheme: MetricSlateComponentThemes.dialog(palette, textTheme),
      snackBarTheme: MetricSlateComponentThemes.snackBar(palette),
      bottomSheetTheme: MetricSlateComponentThemes.bottomSheet(palette),
      listTileTheme: MetricSlateComponentThemes.listTile(palette, textTheme),
      iconButtonTheme: MetricSlateComponentThemes.iconButton(palette),
      dividerTheme: MetricSlateComponentThemes.divider(palette),
      progressIndicatorTheme: MetricSlateComponentThemes.progress(palette),
    );
  }
}
