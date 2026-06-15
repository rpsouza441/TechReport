import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/presentation/view_models/sync_center_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_section_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key, required this.viewModel});

  final SyncCenterViewModel viewModel;

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Central de sincronização')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.items.isEmpty) {
            return TechReportStateView.empty(
              title: 'Tudo sincronizado',
              message: 'Não há itens pendentes ou com erro.',
            );
          }

          return RefreshIndicator(
            onRefresh: vm.load,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildSummary(vm)),
                if (vm.retryError != null)
                  SliverToBoxAdapter(child: _buildErrorBanner(vm.retryError!)),
                if (vm.hasActionable)
                  SliverToBoxAdapter(child: _buildRetryButton(context, vm)),
                _buildSection('Pendentes', vm.pending, vm),
                _buildSection('Com erro', vm.failed, vm),
                _buildSection('Sincronizados recentes', vm.synced, vm),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MetricSlateSpacing.lg),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MetricSlateSpacing.md,
        MetricSlateSpacing.md,
        MetricSlateSpacing.md,
        0,
      ),
      child: TechReportCard(
        child: const TechReportFormHeader(
          icon: Icons.sync_outlined,
          title: 'Fila de sincronização',
          subtitle:
              'Acompanhe envios pendentes, falhas recentes e itens já sincronizados.',
        ),
      ),
    );
  }

  Widget _buildSummary(SyncCenterViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(MetricSlateSpacing.md),
      child: Wrap(
        spacing: MetricSlateSpacing.xs,
        runSpacing: MetricSlateSpacing.xs,
        children: [
          TechReportStatusChip(
            label: 'Pendentes',
            count: vm.pending.length,
            tone: TechReportStatusTone.warning,
            icon: Icons.schedule,
          ),
          TechReportStatusChip(
            label: 'Com erro',
            count: vm.failed.length,
            tone: TechReportStatusTone.error,
            icon: Icons.error_outline,
          ),
          TechReportStatusChip(
            label: 'Enviados',
            count: vm.synced.length,
            tone: TechReportStatusTone.success,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MetricSlateSpacing.md,
        0,
        MetricSlateSpacing.md,
        MetricSlateSpacing.xs,
      ),
      child: TechReportErrorBanner(message: message),
    );
  }

  Widget _buildRetryButton(BuildContext context, SyncCenterViewModel vm) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MetricSlateSpacing.md,
        0,
        MetricSlateSpacing.md,
        MetricSlateSpacing.sm,
      ),
      child: FilledButton.icon(
        onPressed: vm.isRetrying ? null : vm.retryFailed,
        icon: vm.isRetrying
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onPrimary,
                ),
              )
            : const Icon(Icons.sync, size: 20),
        label: Text(vm.isRetrying ? 'Tentando...' : 'Tentar novamente'),
      ),
    );
  }

  Widget _buildSection(String title, List<SyncItem> items, SyncCenterViewModel vm) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: MetricSlateSpacing.md),
      sliver: SliverList.separated(
        itemCount: items.length + 1,
        separatorBuilder: (context, index) {
          if (index == 0) {
            return const SizedBox(height: MetricSlateSpacing.xs);
          }
          return const SizedBox(height: MetricSlateSpacing.sm);
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            return TechReportSectionHeader(
              title: title,
              padding: EdgeInsets.zero,
            );
          }
          return _SyncItemCard(item: items[index - 1], getRatInfo: vm.getRatInfo);
        },
      ),
    );
  }
}

class _SyncItemCard extends StatelessWidget {
  const _SyncItemCard({required this.item, required this.getRatInfo});

  final SyncItem item;
  final String Function(SyncItem) getRatInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorText = item.lastError;
    final showError = errorText != null && item.status == SyncItemStatus.failed;

    return TechReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statusIcon(context, item.status),
              const SizedBox(width: MetricSlateSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _itemTitle(item, getRatInfo(item)),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: MetricSlateSpacing.xxs),
                    Text(
                      _itemSubtitle(item),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TechReportStatusChip(
                label: _syncItemStatusLabel(item.status),
                tone: _syncItemStatusTone(item.status),
              ),
            ],
          ),
          if (showError) ...[
            const SizedBox(height: MetricSlateSpacing.sm),
            Text(
              _friendlyError(errorText),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusIcon(BuildContext context, SyncItemStatus status) {
    final scheme = Theme.of(context).colorScheme;

    return switch (status) {
      SyncItemStatus.pending => Icon(Icons.schedule, color: scheme.tertiary),
      SyncItemStatus.processing => SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
      ),
      SyncItemStatus.synced => Icon(
        Icons.check_circle_outline,
        color: scheme.primary,
      ),
      SyncItemStatus.failed => Icon(Icons.error_outline, color: scheme.error),
    };
  }
}

String _entityTypeLabel(SyncEntityType type) {
  return switch (type) {
    SyncEntityType.rat => 'RAT',
    SyncEntityType.assinatura => 'Assinatura',
  };
}

String? _operationLabel(SyncOperation op) {
  return switch (op) {
    SyncOperation.upsert => null,
    SyncOperation.delete => 'exclusão',
  };
}

String _itemTitle(SyncItem item, String ratInfo) {
  if (item.entityType == SyncEntityType.rat && ratInfo.isNotEmpty) {
    final op = _operationLabel(item.operation);
    return op == null ? ratInfo : '$ratInfo · $op';
  }
  final label = _entityTypeLabel(item.entityType);
  final op = _operationLabel(item.operation);
  return op == null ? label : '$label · $op';
}

String _itemSubtitle(SyncItem item) {
  final date = _formatDate(item.updatedAt);
  if (item.status == SyncItemStatus.synced) {
    return date;
  }
  return 'Tentativas: ${item.attempts} · $date';
}

String _syncItemStatusLabel(SyncItemStatus status) {
  return switch (status) {
    SyncItemStatus.pending => 'Pendente',
    SyncItemStatus.processing => 'Processando',
    SyncItemStatus.synced => 'Enviado',
    SyncItemStatus.failed => 'Erro',
  };
}

TechReportStatusTone _syncItemStatusTone(SyncItemStatus status) {
  return switch (status) {
    SyncItemStatus.pending => TechReportStatusTone.warning,
    SyncItemStatus.processing => TechReportStatusTone.info,
    SyncItemStatus.synced => TechReportStatusTone.success,
    SyncItemStatus.failed => TechReportStatusTone.error,
  };
}

String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

String _friendlyError(String raw) {
  if (raw.contains('SocketException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('Connection refused')) {
    return 'Sem conexão com o servidor.';
  }
  if (raw.contains('401') || raw.contains('403')) {
    return 'Sessão expirada ou sem permissão.';
  }
  if (raw.contains('500') || raw.contains('502') || raw.contains('503')) {
    return 'Erro no servidor. Tente mais tarde.';
  }
  return 'Falha ao sincronizar. Tente novamente.';
}
