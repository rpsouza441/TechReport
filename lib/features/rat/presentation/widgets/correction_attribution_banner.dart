import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';

class CorrectionAttributionBanner extends StatelessWidget {
  const CorrectionAttributionBanner({super.key, required this.ownerName});

  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = 'Corrigindo RAT de $ownerName';
    final body =
        'A RAT continuará pertencendo a $ownerName. '
        'Suas alterações serão registradas no histórico.';
    return Semantics(
      container: true,
      label: '$title. $body',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MetricSlateSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.edit_note_outlined, color: scheme.onPrimaryContainer),
              const SizedBox(width: MetricSlateSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: MetricSlateSpacing.xs),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
