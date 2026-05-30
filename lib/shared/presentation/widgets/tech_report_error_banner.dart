import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';

/// Banner de erro/aviso para formularios.
class TechReportErrorBanner extends StatelessWidget {
  const TechReportErrorBanner({
    super.key,
    required this.message,
    this.tone = TechReportCardTone.error,
  });

  final String message;
  final TechReportCardTone tone;

  @override
  Widget build(BuildContext context) {
    return TechReportCard(
      tone: tone,
      padding: const EdgeInsets.all(MetricSlateSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == TechReportCardTone.warning
                ? Icons.warning_amber_outlined
                : Icons.error_outline,
            size: 22,
          ),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
