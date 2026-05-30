import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';

/// Linha label/valor reutilizavel (perfil, importacao, resumos).
class TechReportInfoRow extends StatelessWidget {
  const TechReportInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.dense = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final vertical = dense ? MetricSlateSpacing.xxs : MetricSlateSpacing.xs;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: scheme.primary),
            const SizedBox(width: MetricSlateSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: icon != null
                  ? theme.textTheme.labelLarge
                  : theme.textTheme.bodyLarge,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
