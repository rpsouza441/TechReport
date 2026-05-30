import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';

/// Cabecalho de secao em listas e formularios longos.
class TechReportSectionHeader extends StatelessWidget {
  const TechReportSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: MetricSlateSpacing.xxs),
          Text(subtitle!, style: theme.textTheme.bodyMedium),
        ],
      ],
    );

    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            MetricSlateSpacing.md,
            MetricSlateSpacing.md,
            MetricSlateSpacing.md,
            MetricSlateSpacing.xxs,
          ),
      child: trailing == null
          ? content
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: content),
                trailing!,
              ],
            ),
    );
  }
}
