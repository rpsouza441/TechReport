import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_radii.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';
import 'package:techreport/features/rat/presentation/widgets/rat_list_item_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

class TrashRatCard extends StatelessWidget {
  const TrashRatCard({
    super.key,
    required this.rat,
    required this.hasSignature,
    required this.onOpenDetails,
    required this.onRestore,
    this.ownerName,
    this.showOwner = false,
    this.showSyncStatus = false,
    this.isRestoring = false,
  });

  final Rat rat;
  final bool hasSignature;
  final VoidCallback onOpenDetails;
  final VoidCallback onRestore;
  final String? ownerName;
  final bool showOwner;
  final bool showSyncStatus;
  final bool isRestoring;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deletedAt = rat.deletedAt;

    return Semantics(
      container: true,
      label:
          'RAT ${rat.numero}, ${rat.clienteNome}, ${ratStatusLabel(rat.status)}, '
          '${hasSignature ? 'com assinatura' : 'sem assinatura'}, '
          '${deletedAt == null ? 'data de exclusão não informada' : _deletedLabel(deletedAt)}',
      child: TechReportCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(MetricSlateRadii.md),
              onTap: isRestoring ? null : onOpenDetails,
              child: Padding(
                padding: const EdgeInsets.only(bottom: MetricSlateSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rat.clienteNome, style: theme.textTheme.titleMedium),
                    const SizedBox(height: MetricSlateSpacing.xxs),
                    Text(
                      'RAT ${rat.numero}',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: MetricSlateSpacing.xs),
                    Text(
                      rat.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: MetricSlateSpacing.sm),
                    Wrap(
                      spacing: MetricSlateSpacing.xs,
                      runSpacing: MetricSlateSpacing.xs,
                      children: [
                        TechReportStatusChip(
                          label: ratStatusLabel(rat.status),
                          tone: ratStatusTone(rat.status),
                        ),
                        TechReportStatusChip(
                          label: hasSignature ? 'Assinada' : 'Sem assinatura',
                          tone: hasSignature
                              ? TechReportStatusTone.success
                              : TechReportStatusTone.neutral,
                          icon: hasSignature ? Icons.draw : Icons.draw_outlined,
                        ),
                        if (showSyncStatus)
                          TechReportStatusChip(
                            label: ratSyncStatusLabel(rat.syncStatus),
                            tone: ratSyncStatusTone(rat.syncStatus),
                            icon: ratSyncStatusIcon(rat.syncStatus),
                          ),
                      ],
                    ),
                    const SizedBox(height: MetricSlateSpacing.sm),
                    Text(
                      deletedAt == null
                          ? 'Data da lixeira não informada'
                          : _deletedLabel(deletedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (showOwner) ...[
                      const SizedBox(height: MetricSlateSpacing.xs),
                      Text(
                        'Proprietário: $_ownerLabel',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: MetricSlateSpacing.xs),
            SizedBox(
              height: 48,
              child: FilledButton.tonalIcon(
                onPressed: isRestoring ? null : onRestore,
                icon: isRestoring
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore_outlined),
                label: Text(isRestoring ? 'Restaurando...' : 'Restaurar RAT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _ownerLabel {
    final value = ownerName?.trim();
    if (value != null && value.isNotEmpty) return value;
    final technician = rat.tecnicoId;
    return technician == null || technician.isEmpty
        ? 'Não informado'
        : 'Técnico · ${technician.length <= 8 ? technician : technician.substring(0, 8)}';
  }

  String _deletedLabel(DateTime value) {
    final local = value.toLocal();
    return 'Movida para a lixeira em '
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} às '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
