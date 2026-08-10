import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/domain/entities/rat_audit_event.dart';

class RatAuditDiffRow extends StatelessWidget {
  const RatAuditDiffRow({super.key, required this.diff});

  final RatAuditFieldDiff diff;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${diff.label}. Antes: ${_value(diff.beforeValue)}. '
          'Depois: ${_value(diff.afterValue)}.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(diff.label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: MetricSlateSpacing.xs),
            LayoutBuilder(
              builder: (context, constraints) {
                final before = _AuditValue(
                  label: 'Antes',
                  value: _value(diff.beforeValue),
                );
                final after = _AuditValue(
                  label: 'Depois',
                  value: _value(diff.afterValue),
                );
                if (constraints.maxWidth < 840) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      before,
                      const SizedBox(height: MetricSlateSpacing.sm),
                      after,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: before),
                    const SizedBox(width: MetricSlateSpacing.md),
                    Expanded(child: after),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _value(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty
        ? 'Não informado'
        : normalized;
  }
}

class _AuditValue extends StatefulWidget {
  const _AuditValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  State<_AuditValue> createState() => _AuditValueState();
}

class _AuditValueState extends State<_AuditValue> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MetricSlateSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.label, style: theme.textTheme.labelLarge),
            const SizedBox(height: MetricSlateSpacing.xxs),
            SelectableText(
              widget.value,
              maxLines: _expanded ? null : 3,
              style: theme.textTheme.bodyMedium,
            ),
            if (!_expanded && _mayOverflow(widget.value))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = true),
                  child: const Text('Ver valor completo'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _mayOverflow(String value) => value.length > 120 || value.contains('\n');
}
