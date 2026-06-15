import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';

class LocalInfoCard extends StatelessWidget {
  const LocalInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.iconSize = 24,
    this.gap = MetricSlateSpacing.md,
    this.titleStyle,
    this.bodyStyle,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final double iconSize;
  final double gap;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: theme.colorScheme.primary),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle ?? theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(body, style: bodyStyle ?? theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: MetricSlateSpacing.sm),
            trailing!,
          ] else if (showChevron) ...[
            const SizedBox(width: MetricSlateSpacing.sm),
            const Icon(Icons.chevron_right),
          ],
        ],
      ),
    );
  }
}
