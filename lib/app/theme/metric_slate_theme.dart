import 'package:flutter/material.dart';

import 'metric_slate_colors.dart';

class MetricSlateTheme {
  const MetricSlateTheme._();

  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: MetricSlateColors.primary,
      onPrimary: Colors.white,
      primaryContainer: MetricSlateColors.primaryContainer,
      secondary: MetricSlateColors.secondary,
      secondaryContainer: MetricSlateColors.secondaryContainer,
      tertiary: MetricSlateColors.tertiary,
      surface: MetricSlateColors.surface,
      onSurface: MetricSlateColors.onSurface,
      error: MetricSlateColors.error,
      outline: MetricSlateColors.outline,
      outlineVariant: MetricSlateColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MetricSlateColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: MetricSlateColors.surface,
        foregroundColor: MetricSlateColors.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MetricSlateColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: MetricSlateColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
