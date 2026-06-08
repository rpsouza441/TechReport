import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_radii.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

class RatListItemCard extends StatelessWidget {
  const RatListItemCard({
    super.key,
    required this.rat,
    required this.hasSignature,
    required this.onTap,
    required this.onPreviewPdf,
    this.showSyncStatus = true,
    this.trailingDate,
  });

  final Rat rat;
  final bool hasSignature;
  final VoidCallback onTap;
  final VoidCallback onPreviewPdf;
  final bool showSyncStatus;
  final DateTime? trailingDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(MetricSlateRadii.md),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rat.clienteNome, style: theme.textTheme.titleMedium),
                      const SizedBox(height: MetricSlateSpacing.xxs),
                      Text(rat.numero, style: theme.textTheme.labelMedium),
                      const SizedBox(height: MetricSlateSpacing.xs),
                      Text(
                        rat.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (hasSignature)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: MetricSlateSpacing.xs,
                          bottom: MetricSlateSpacing.xxs,
                        ),
                        child: Icon(
                          Icons.draw_outlined,
                          size: 22,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    IconButton(
                      onPressed: onPreviewPdf,
                      icon: Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: 'Prévia do PDF',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            _buildChips(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildChips(ThemeData theme) {
    final chips = <Widget>[
      TechReportStatusChip(
        label: ratStatusLabel(rat.status),
        tone: ratStatusTone(rat.status),
      ),
    ];

    if (showSyncStatus) {
      chips.add(
        TechReportStatusChip(
          label: ratSyncStatusLabel(rat.syncStatus),
          tone: ratSyncStatusTone(rat.syncStatus),
          icon: ratSyncStatusIcon(rat.syncStatus),
        ),
      );
    }

    if (trailingDate != null) {
      chips.add(
        Text(
          _formatDate(trailingDate!),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Wrap(
      spacing: MetricSlateSpacing.xs,
      runSpacing: MetricSlateSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

// ─── Helpers de sync (moved from rat_list_screen.dart) ────────────────────────

String ratSyncStatusLabel(RatSyncStatus status) {
  return switch (status) {
    RatSyncStatus.localOnly => 'Local',
    RatSyncStatus.pendingSync => 'Pendente',
    RatSyncStatus.synced => 'Sincronizado',
    RatSyncStatus.syncError => 'Erro de sync',
  };
}

TechReportStatusTone ratSyncStatusTone(RatSyncStatus status) {
  return switch (status) {
    RatSyncStatus.localOnly => TechReportStatusTone.neutral,
    RatSyncStatus.pendingSync => TechReportStatusTone.warning,
    RatSyncStatus.synced => TechReportStatusTone.success,
    RatSyncStatus.syncError => TechReportStatusTone.error,
  };
}

IconData? ratSyncStatusIcon(RatSyncStatus status) {
  return switch (status) {
    RatSyncStatus.localOnly => Icons.smartphone_outlined,
    RatSyncStatus.pendingSync => Icons.schedule,
    RatSyncStatus.synced => Icons.cloud_done_outlined,
    RatSyncStatus.syncError => Icons.error_outline,
  };
}
