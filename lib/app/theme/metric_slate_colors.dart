import 'package:flutter/material.dart';

enum MetricSlateThemeFamily { cobalt, volt, burgundy }

class MetricSlatePalette {
  const MetricSlatePalette({
    required this.family,
    required this.brightness,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.primaryDeep,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.outline,
    required this.outlineVariant,
  });

  final MetricSlateThemeFamily family;
  final Brightness brightness;
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color primary;
  final Color primaryDeep;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color outline;
  final Color outlineVariant;

  bool get isDark => brightness == Brightness.dark;
}

class MetricSlateColors {
  const MetricSlateColors._();

  static const defaultFamily = MetricSlateThemeFamily.cobalt;
  static const defaultBrightness = Brightness.light;

  static MetricSlatePalette get defaultPalette =>
      paletteFor(family: defaultFamily, brightness: defaultBrightness);

  static const cobaltLight = MetricSlatePalette(
    family: MetricSlateThemeFamily.cobalt,
    brightness: Brightness.light,
    surface: Color(0xFFF8F9FF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEFF4FF),
    surfaceContainer: Color(0xFFE5EEFF),
    surfaceContainerHigh: Color(0xFFDCE9FF),
    surfaceContainerHighest: Color(0xFFD3E4FE),
    onSurface: Color(0xFF0B1C30),
    onSurfaceVariant: Color(0xFF444653),
    primary: Color(0xFF1E40AF),
    primaryDeep: Color(0xFF00288E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDDE1FF),
    onPrimaryContainer: Color(0xFF001453),
    secondary: Color(0xFF565E74),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDAE2FD),
    onSecondaryContainer: Color(0xFF131B2E),
    tertiary: Color(0xFF2F353B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDDE3EB),
    onTertiaryContainer: Color(0xFF161C22),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    outline: Color(0xFF757684),
    outlineVariant: Color(0xFFC4C5D5),
  );

  static const cobaltDark = MetricSlatePalette(
    family: MetricSlateThemeFamily.cobalt,
    brightness: Brightness.dark,
    surface: Color(0xFF0B1C30),
    surfaceContainerLowest: Color(0xFF07111E),
    surfaceContainerLow: Color(0xFF10243A),
    surfaceContainer: Color(0xFF172C44),
    surfaceContainerHigh: Color(0xFF213650),
    surfaceContainerHighest: Color(0xFF2C425E),
    onSurface: Color(0xFFEAF1FF),
    onSurfaceVariant: Color(0xFFC4C5D5),
    primary: Color(0xFFB8C4FF),
    primaryDeep: Color(0xFF00288E),
    onPrimary: Color(0xFF001453),
    primaryContainer: Color(0xFF1E40AF),
    onPrimaryContainer: Color(0xFFDDE1FF),
    secondary: Color(0xFFBEC6E0),
    onSecondary: Color(0xFF131B2E),
    secondaryContainer: Color(0xFF3F465C),
    onSecondaryContainer: Color(0xFFDAE2FD),
    tertiary: Color(0xFFC1C7CF),
    onTertiary: Color(0xFF161C22),
    tertiaryContainer: Color(0xFF41474E),
    onTertiaryContainer: Color(0xFFDDE3EB),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    outline: Color(0xFF8E909D),
    outlineVariant: Color(0xFF444653),
  );

  static const voltLight = MetricSlatePalette(
    family: MetricSlateThemeFamily.volt,
    brightness: Brightness.light,
    surface: Color(0xFFF8FAFC),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF1F5F9),
    surfaceContainer: Color(0xFFE2E8F0),
    surfaceContainerHigh: Color(0xFFCBD5E1),
    surfaceContainerHighest: Color(0xFFB9C7D8),
    onSurface: Color(0xFF101415),
    onSurfaceVariant: Color(0xFF334155),
    primary: Color(0xFF4C6700),
    primaryDeep: Color(0xFF2B3D00),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFBCF723),
    onPrimaryContainer: Color(0xFF141F00),
    secondary: Color(0xFF334155),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD5E3FD),
    onSecondaryContainer: Color(0xFF0D1C2F),
    tertiary: Color(0xFF007A55),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFA7F3D0),
    onTertiaryContainer: Color(0xFF002115),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFFCBD5E1),
  );

  static const voltDark = MetricSlatePalette(
    family: MetricSlateThemeFamily.volt,
    brightness: Brightness.dark,
    surface: Color(0xFF0F131D),
    surfaceContainerLowest: Color(0xFF0A0E18),
    surfaceContainerLow: Color(0xFF171B26),
    surfaceContainer: Color(0xFF1C1F2A),
    surfaceContainerHigh: Color(0xFF262A35),
    surfaceContainerHighest: Color(0xFF313540),
    onSurface: Color(0xFFDFE2F1),
    onSurfaceVariant: Color(0xFFC3CAAE),
    primary: Color(0xFFBCF723),
    primaryDeep: Color(0xFF384E00),
    onPrimary: Color(0xFF141F00),
    primaryContainer: Color(0xFF384E00),
    onPrimaryContainer: Color(0xFFBCF723),
    secondary: Color(0xFFB9C7E0),
    onSecondary: Color(0xFF0D1C2F),
    secondaryContainer: Color(0xFF3C4A5E),
    onSecondaryContainer: Color(0xFFD5E3FD),
    tertiary: Color(0xFFA7F3D0),
    onTertiary: Color(0xFF002115),
    tertiaryContainer: Color(0xFF00513A),
    onTertiaryContainer: Color(0xFFA6F2CF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    outline: Color(0xFF8D947A),
    outlineVariant: Color(0xFF434934),
  );

  static const burgundyLight = MetricSlatePalette(
    family: MetricSlateThemeFamily.burgundy,
    brightness: Brightness.light,
    surface: Color(0xFFFFF8F7),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAF2F1),
    surfaceContainer: Color(0xFFF4ECEB),
    surfaceContainerHigh: Color(0xFFEEE6E6),
    surfaceContainerHighest: Color(0xFFE9E1E0),
    onSurface: Color(0xFF1E1B1B),
    onSurfaceVariant: Color(0xFF554243),
    primary: Color(0xFF5C0D1C),
    primaryDeep: Color(0xFF40000D),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDADB),
    onPrimaryContainer: Color(0xFF40000D),
    secondary: Color(0xFF851C31),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFDADB),
    onSecondaryContainer: Color(0xFF40000F),
    tertiary: Color(0xFFD4A373),
    onTertiary: Color(0xFF281400),
    tertiaryContainer: Color(0xFFFFDCBD),
    onTertiaryContainer: Color(0xFF2C1600),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    outline: Color(0xFF887272),
    outlineVariant: Color(0xFFDBC0C1),
  );

  static const burgundyDark = MetricSlatePalette(
    family: MetricSlateThemeFamily.burgundy,
    brightness: Brightness.dark,
    surface: Color(0xFF181515),
    surfaceContainerLowest: Color(0xFF100D0D),
    surfaceContainerLow: Color(0xFF211C1C),
    surfaceContainer: Color(0xFF2A2223),
    surfaceContainerHigh: Color(0xFF352B2C),
    surfaceContainerHighest: Color(0xFF423536),
    onSurface: Color(0xFFF7EFEE),
    onSurfaceVariant: Color(0xFFDBC0C1),
    primary: Color(0xFFFFB2B7),
    primaryDeep: Color(0xFF5C0D1C),
    onPrimary: Color(0xFF40000D),
    primaryContainer: Color(0xFF7E2834),
    onPrimaryContainer: Color(0xFFFFDADB),
    secondary: Color(0xFFFFB2B8),
    onSecondary: Color(0xFF40000F),
    secondaryContainer: Color(0xFF871D32),
    onSecondaryContainer: Color(0xFFFFDADB),
    tertiary: Color(0xFFF0BD8B),
    onTertiary: Color(0xFF2C1600),
    tertiaryContainer: Color(0xFF623F18),
    onTertiaryContainer: Color(0xFFFFDCBD),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    outline: Color(0xFFA58B8C),
    outlineVariant: Color(0xFF554243),
  );

  static MetricSlatePalette paletteFor({
    required MetricSlateThemeFamily family,
    required Brightness brightness,
  }) {
    return switch ((family, brightness)) {
      (MetricSlateThemeFamily.cobalt, Brightness.light) => cobaltLight,
      (MetricSlateThemeFamily.cobalt, Brightness.dark) => cobaltDark,
      (MetricSlateThemeFamily.volt, Brightness.light) => voltLight,
      (MetricSlateThemeFamily.volt, Brightness.dark) => voltDark,
      (MetricSlateThemeFamily.burgundy, Brightness.light) => burgundyLight,
      (MetricSlateThemeFamily.burgundy, Brightness.dark) => burgundyDark,
    };
  }

  static const surface = Color(0xFFF8F9FF);
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF444653);
  static const primary = Color(0xFF1E40AF);
  static const primaryDeep = Color(0xFF00288E);
  static const primaryContainer = Color(0xFFDDE1FF);
  static const primaryFixed = Color(0xFFDDE1FF);
  static const secondary = Color(0xFF565E74);
  static const secondaryContainer = Color(0xFFDAE2FD);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerHighest = Color(0xFFD3E4FE);
  static const outline = Color(0xFF757684);
  static const outlineVariant = Color(0xFFC4C5D5);
  static const tertiary = Color(0xFF2F353B);
  static const error = Color(0xFFBA1A1A);
}
