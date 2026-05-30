import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/theme/metric_slate_colors.dart';
import 'package:techreport/app/theme/metric_slate_theme.dart';

void main() {
  test('default palette usa Cobalt light do Stitch', () {
    final palette = MetricSlateColors.defaultPalette;

    expect(palette.family, MetricSlateThemeFamily.cobalt);
    expect(palette.brightness, Brightness.light);
    expect(palette.surface, const Color(0xFFF8F9FF));
    expect(palette.onSurface, const Color(0xFF0B1C30));
    expect(palette.primary, const Color(0xFF1E40AF));
    expect(palette.primaryDeep, const Color(0xFF00288E));
    expect(palette.secondary, const Color(0xFF565E74));
    expect(palette.secondaryContainer, const Color(0xFFDAE2FD));
    expect(palette.outline, const Color(0xFF757684));
    expect(palette.error, const Color(0xFFBA1A1A));
  });

  test('MetricSlateTheme.light expoe ColorScheme com containers', () {
    final theme = MetricSlateTheme.light();
    final scheme = theme.colorScheme;

    expect(scheme.brightness, Brightness.light);
    expect(scheme.primary, const Color(0xFF1E40AF));
    expect(scheme.surface, const Color(0xFFF8F9FF));
    expect(scheme.surfaceContainerLow, const Color(0xFFEFF4FF));
    expect(scheme.onSurfaceVariant, const Color(0xFF444653));
  });
}
