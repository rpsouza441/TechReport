import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_view_model.dart';
import 'package:techreport/features/rat/presentation/widgets/rat_date_range_field.dart';

class RatListFilterBar extends StatelessWidget {
  const RatListFilterBar({required this.viewModel, super.key});

  final RatListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MetricSlateSpacing.md,
          MetricSlateSpacing.sm,
          MetricSlateSpacing.md,
          MetricSlateSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar cliente ou descrição',
                prefixIcon: Icon(Icons.search, size: 22),
              ),
              onChanged: viewModel.setQuery,
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _StatusFilter(viewModel: viewModel)),
                const SizedBox(width: MetricSlateSpacing.sm),
                Expanded(
                  child: RatDateRangeField(
                    dateFrom: viewModel.dateFrom,
                    dateTo: viewModel.dateTo,
                    onChanged: viewModel.setDateRange,
                    onClear: viewModel.clearDateRange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.viewModel});

  final RatListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Status do RAT',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<RatStatus?>(
            isExpanded: true,
            value: viewModel.statusFilter,
            hint: const Text('Todos'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: RatStatus.draft, child: Text('Rascunho')),
              DropdownMenuItem(
                value: RatStatus.finalizado,
                child: Text('Finalizado'),
              ),
              DropdownMenuItem(
                value: RatStatus.enviado,
                child: Text('Enviado'),
              ),
              DropdownMenuItem(
                value: RatStatus.arquivado,
                child: Text('Arquivado'),
              ),
            ],
            onChanged: viewModel.setStatusFilter,
          ),
        ),
        Divider(height: 1, color: scheme.outline),
      ],
    );
  }
}
