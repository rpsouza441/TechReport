import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';

/// Título padrão de AppBar: "Tech Report" + badge do modo atual.
///
/// Usado no shell do Modo Local ("Modo Local") e do Modo Empresa
/// ("Modo Empresa") para manter o cabeçalho consistente entre os modos.
class TechReportModeTitle extends StatelessWidget {
  const TechReportModeTitle({required this.modeLabel, super.key});

  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Text('Tech Report'),
        const SizedBox(width: MetricSlateSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MetricSlateSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            modeLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
