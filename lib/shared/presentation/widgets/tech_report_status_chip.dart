import 'package:flutter/material.dart';

enum TechReportStatusTone { neutral, info, success, warning, error }

/// Chip de status (sync, RAT, resumos) com cores do tema.
class TechReportStatusChip extends StatelessWidget {
  const TechReportStatusChip({
    super.key,
    required this.label,
    this.count,
    this.tone = TechReportStatusTone.neutral,
    this.icon,
  });

  final String label;
  final int? count;
  final TechReportStatusTone tone;
  final IconData? icon;

  String get _text {
    if (count == null) {
      return label;
    }
    return '$label: $count';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accentColor(scheme);

    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 18, color: accent),
      label: Text(_text),
      side: BorderSide(color: accent.withValues(alpha: 0.5)),
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Color _accentColor(ColorScheme scheme) {
    return switch (tone) {
      TechReportStatusTone.neutral => scheme.outline,
      TechReportStatusTone.info => scheme.primary,
      TechReportStatusTone.success => scheme.primary,
      TechReportStatusTone.warning => scheme.tertiary,
      TechReportStatusTone.error => scheme.error,
    };
  }
}
