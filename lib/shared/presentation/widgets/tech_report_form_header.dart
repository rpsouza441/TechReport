import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';

/// Cabecalho padrao de formularios Metric Slate (icone + titulo + subtitulo).
class TechReportFormHeader extends StatelessWidget {
  const TechReportFormHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 32, color: scheme.primary),
            const SizedBox(width: MetricSlateSpacing.xs),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MetricSlateSpacing.xxs),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
