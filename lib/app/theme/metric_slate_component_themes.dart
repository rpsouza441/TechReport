import 'package:flutter/material.dart';

import 'metric_slate_colors.dart';
import 'metric_slate_radii.dart';
import 'metric_slate_spacing.dart';

/// Themes de componentes Material para Metric Slate (Sprint 8.1 etapa 2).
class MetricSlateComponentThemes {
  const MetricSlateComponentThemes._();

  static ColorScheme colorScheme(MetricSlatePalette palette) {
    return ColorScheme(
      brightness: palette.brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      secondaryContainer: palette.secondaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
      tertiary: palette.tertiary,
      onTertiary: palette.onTertiary,
      tertiaryContainer: palette.tertiaryContainer,
      onTertiaryContainer: palette.onTertiaryContainer,
      error: palette.error,
      onError: palette.onError,
      errorContainer: palette.errorContainer,
      onErrorContainer: palette.onErrorContainer,
      surface: palette.surface,
      onSurface: palette.onSurface,
      onSurfaceVariant: palette.onSurfaceVariant,
      surfaceContainerLowest: palette.surfaceContainerLowest,
      surfaceContainerLow: palette.surfaceContainerLow,
      surfaceContainer: palette.surfaceContainer,
      surfaceContainerHigh: palette.surfaceContainerHigh,
      surfaceContainerHighest: palette.surfaceContainerHighest,
      outline: palette.outline,
      outlineVariant: palette.outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: palette.onSurface,
      onInverseSurface: palette.surface,
      inversePrimary: palette.primaryContainer,
      surfaceTint: palette.primary,
    );
  }

  static TextTheme textTheme(MetricSlatePalette palette) {
    final typography = palette.isDark
        ? Typography.material2021(platform: TargetPlatform.android).white
        : Typography.material2021(platform: TargetPlatform.android).black;

    final base = palette.onSurface;
    final muted = palette.onSurfaceVariant;

    TextStyle? withColor(TextStyle? style, Color color, {FontWeight? weight}) {
      return style?.copyWith(
        color: color,
        fontWeight: weight ?? style.fontWeight,
      );
    }

    return typography.copyWith(
      displayLarge: withColor(
        typography.displayLarge,
        base,
        weight: FontWeight.w600,
      ),
      displayMedium: withColor(
        typography.displayMedium,
        base,
        weight: FontWeight.w600,
      ),
      displaySmall: withColor(
        typography.displaySmall,
        base,
        weight: FontWeight.w600,
      ),
      headlineLarge: withColor(
        typography.headlineLarge,
        base,
        weight: FontWeight.w600,
      ),
      headlineMedium: withColor(
        typography.headlineMedium,
        base,
        weight: FontWeight.w600,
      ),
      headlineSmall: withColor(
        typography.headlineSmall,
        base,
        weight: FontWeight.w600,
      ),
      titleLarge: withColor(
        typography.titleLarge,
        base,
        weight: FontWeight.w600,
      ),
      titleMedium: withColor(
        typography.titleMedium,
        base,
        weight: FontWeight.w600,
      ),
      titleSmall: withColor(
        typography.titleSmall,
        base,
        weight: FontWeight.w600,
      ),
      bodyLarge: withColor(typography.bodyLarge, base),
      bodyMedium: withColor(typography.bodyMedium, muted),
      bodySmall: withColor(typography.bodySmall, muted),
      labelLarge: withColor(
        typography.labelLarge,
        base,
        weight: FontWeight.w600,
      ),
      labelMedium: withColor(
        typography.labelMedium,
        muted,
        weight: FontWeight.w600,
      ),
      labelSmall: withColor(
        typography.labelSmall,
        muted,
        weight: FontWeight.w600,
      ),
    );
  }

  static RoundedRectangleBorder controlShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MetricSlateRadii.sm),
    );
  }

  static AppBarTheme appBar(MetricSlatePalette palette, TextTheme textTheme) {
    return AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: palette.surface.withValues(alpha: 0.96),
      foregroundColor: palette.onSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: palette.onSurface,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: palette.onSurface, size: 24),
      actionsIconTheme: IconThemeData(color: palette.onSurface, size: 24),
    );
  }

  static CardThemeData card(MetricSlatePalette palette) {
    return CardThemeData(
      color: palette.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: palette.isDark ? 0 : 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shadowColor: palette.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MetricSlateRadii.md),
        side: BorderSide(
          color: palette.outlineVariant.withValues(
            alpha: palette.isDark ? 0.48 : 0.72,
          ),
        ),
      ),
    );
  }

  static InputDecorationTheme input(MetricSlatePalette palette) {
    final radius = BorderRadius.circular(MetricSlateRadii.sm);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: palette.outlineVariant),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceContainerLow,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MetricSlateSpacing.inputHorizontal,
        vertical: MetricSlateSpacing.inputVertical,
      ),
      constraints: const BoxConstraints(
        minHeight: MetricSlateSpacing.touchTarget,
      ),
      labelStyle: TextStyle(color: palette.onSurfaceVariant),
      floatingLabelStyle: TextStyle(
        color: palette.primary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: palette.onSurfaceVariant),
      errorStyle: TextStyle(color: palette.error, fontWeight: FontWeight.w500),
      border: border,
      enabledBorder: border,
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: palette.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.error, width: 2),
      ),
    );
  }

  static ButtonStyle _filledStyle(
    MetricSlatePalette palette,
    TextTheme textTheme,
  ) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(MetricSlateSpacing.touchTarget, MetricSlateSpacing.touchTarget),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: MetricSlateSpacing.buttonHorizontal,
          vertical: MetricSlateSpacing.buttonVertical,
        ),
      ),
      shape: WidgetStatePropertyAll(controlShape()),
      textStyle: WidgetStatePropertyAll(
        textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered)) {
          return palette.primaryDeep;
        }
        return palette.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette.onSurface.withValues(alpha: 0.38);
        }
        return palette.onPrimary;
      }),
      elevation: const WidgetStatePropertyAll(0),
      overlayColor: WidgetStatePropertyAll(
        palette.onPrimary.withValues(alpha: 0.12),
      ),
    );
  }

  static FilledButtonThemeData filledButton(
    MetricSlatePalette palette,
    TextTheme textTheme,
  ) {
    return FilledButtonThemeData(style: _filledStyle(palette, textTheme));
  }

  static OutlinedButtonThemeData outlinedButton(
    MetricSlatePalette palette,
    TextTheme textTheme,
  ) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(MetricSlateSpacing.touchTarget, MetricSlateSpacing.touchTarget),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: MetricSlateSpacing.buttonHorizontal,
            vertical: MetricSlateSpacing.buttonVertical,
          ),
        ),
        shape: WidgetStatePropertyAll(controlShape()),
        textStyle: WidgetStatePropertyAll(
          textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.onSurface.withValues(alpha: 0.38);
          }
          return palette.primary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: palette.outline.withValues(alpha: 0.38));
          }
          return BorderSide(color: palette.outline);
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return palette.primaryContainer.withValues(alpha: 0.35);
          }
          return Colors.transparent;
        }),
      ),
    );
  }

  static TextButtonThemeData textButton(
    MetricSlatePalette palette,
    TextTheme textTheme,
  ) {
    return TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(MetricSlateSpacing.touchTarget, 44),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: MetricSlateSpacing.md),
        ),
        textStyle: WidgetStatePropertyAll(
          textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.onSurface.withValues(alpha: 0.38);
          }
          return palette.primary;
        }),
        overlayColor: WidgetStatePropertyAll(
          palette.primary.withValues(alpha: 0.08),
        ),
      ),
    );
  }

  static FloatingActionButtonThemeData fab(MetricSlatePalette palette) {
    return FloatingActionButtonThemeData(
      backgroundColor: palette.primary,
      foregroundColor: palette.onPrimary,
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MetricSlateRadii.md),
      ),
    );
  }

  static NavigationBarThemeData navigationBar(
    MetricSlatePalette palette,
    TextTheme textTheme,
  ) {
    return NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: palette.surface.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      indicatorColor: palette.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MetricSlateRadii.md),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelMedium?.copyWith(
          color: selected
              ? palette.onPrimaryContainer
              : palette.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? palette.onPrimaryContainer
              : palette.onSurfaceVariant,
          size: 24,
        );
      }),
    );
  }

  static ChipThemeData chip(MetricSlatePalette palette, TextTheme textTheme) {
    return ChipThemeData(
      backgroundColor: palette.surfaceContainerLow,
      selectedColor: palette.primaryContainer,
      disabledColor: palette.surfaceContainer,
      labelStyle: textTheme.labelLarge?.copyWith(color: palette.onSurface),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: palette.onPrimaryContainer,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MetricSlateSpacing.sm,
        vertical: MetricSlateSpacing.xxs,
      ),
      side: BorderSide(color: palette.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MetricSlateRadii.pill),
      ),
    );
  }

  static DialogThemeData dialog(
    MetricSlatePalette palette,
    TextTheme textTheme,
  ) {
    return DialogThemeData(
      backgroundColor: palette.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MetricSlateRadii.lg),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: palette.onSurface,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: textTheme.bodyLarge?.copyWith(color: palette.onSurface),
      actionsPadding: const EdgeInsets.fromLTRB(
        MetricSlateSpacing.lg,
        0,
        MetricSlateSpacing.lg,
        MetricSlateSpacing.lg,
      ),
    );
  }

  static SnackBarThemeData snackBar(MetricSlatePalette palette) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      backgroundColor: palette.onSurface,
      contentTextStyle: TextStyle(
        color: palette.surface,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: palette.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MetricSlateRadii.sm),
      ),
    );
  }

  static BottomSheetThemeData bottomSheet(MetricSlatePalette palette) {
    return BottomSheetThemeData(
      backgroundColor: palette.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MetricSlateRadii.lg),
        ),
      ),
      dragHandleColor: palette.outlineVariant,
      showDragHandle: true,
    );
  }

  static ListTileThemeData listTile(
    MetricSlatePalette palette,
    TextTheme textTheme,
  ) {
    return ListTileThemeData(
      iconColor: palette.primary,
      textColor: palette.onSurface,
      titleTextStyle: textTheme.titleMedium,
      subtitleTextStyle: textTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MetricSlateSpacing.md,
        vertical: MetricSlateSpacing.xxs,
      ),
      minVerticalPadding: MetricSlateSpacing.sm,
    );
  }

  static IconButtonThemeData iconButton(MetricSlatePalette palette) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(
          MetricSlateSpacing.touchTarget,
          MetricSlateSpacing.touchTarget,
        ),
        foregroundColor: palette.onSurface,
        highlightColor: palette.primary.withValues(alpha: 0.08),
      ),
    );
  }

  static DividerThemeData divider(MetricSlatePalette palette) {
    return DividerThemeData(
      color: palette.outlineVariant.withValues(alpha: 0.7),
      thickness: 1,
      space: 1,
    );
  }

  static ProgressIndicatorThemeData progress(MetricSlatePalette palette) {
    return ProgressIndicatorThemeData(
      color: palette.primary,
      linearTrackColor: palette.surfaceContainerHigh,
      circularTrackColor: palette.surfaceContainerHigh,
    );
  }
}
