import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_radii.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';

enum TechReportCardTone { normal, warning, error }

/// Card padronizado Metric Slate (herda [CardTheme] no tom normal).
class TechReportCard extends StatelessWidget {
  const TechReportCard({
    super.key,
    required this.child,
    this.padding,
    this.tone = TechReportCardTone.normal,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final TechReportCardTone tone;
  final EdgeInsetsGeometry? margin;

  EdgeInsetsGeometry get _padding =>
      padding ?? const EdgeInsets.all(MetricSlateSpacing.md);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (tone == TechReportCardTone.normal) {
      return Card(
        margin: margin ?? EdgeInsets.zero,
        child: Padding(padding: _padding, child: child),
      );
    }

    final background = switch (tone) {
      TechReportCardTone.warning => scheme.errorContainer,
      TechReportCardTone.error => scheme.errorContainer,
      TechReportCardTone.normal => scheme.surfaceContainerLowest,
    };
    final foreground = scheme.onErrorContainer;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(MetricSlateRadii.xs),
        ),
        child: Padding(
          padding: _padding,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foreground),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
