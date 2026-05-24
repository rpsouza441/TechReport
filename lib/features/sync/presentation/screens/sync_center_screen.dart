import 'package:flutter/material.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/presentation/view_models/sync_center_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';

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
      appBar: AppBar(title: const Text('Sincronizacao')),
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
              message: 'Nao ha itens pendentes ou com erro.',
            );
          }

          return RefreshIndicator(
            onRefresh: vm.load,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSummary(vm)),
                if (vm.retryError != null)
                  SliverToBoxAdapter(child: _buildErrorBanner(vm.retryError!)),
                if (vm.hasActionable)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: FilledButton.icon(
                        onPressed: vm.isRetrying ? null : vm.retryFailed,
                        icon: vm.isRetrying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: const Text('Tentar novamente'),
                      ),
                    ),
                  ),
                _buildSection('Pendentes', vm.pending),
                _buildSection('Com erro', vm.failed),
                _buildSection('Sincronizados recentes', vm.synced),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(SyncCenterViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _summaryChip('Pendentes', vm.pending.length, Colors.orange),
          _summaryChip('Com erro', vm.failed.length, Colors.red),
          _summaryChip('Enviados', vm.synced.length, Colors.green),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count'),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<SyncItem> items) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList.separated(
      itemCount: items.length + 1,
      separatorBuilder: (context, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: Theme.of(context).textTheme.labelLarge),
          );
        }
        return _buildTile(items[index - 1]);
      },
    );
  }

  Widget _buildTile(SyncItem item) {
    final Widget statusIcon;
    switch (item.status) {
      case SyncItemStatus.pending:
        statusIcon = const Icon(Icons.schedule, size: 18);
      case SyncItemStatus.processing:
        statusIcon = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncItemStatus.synced:
        statusIcon = Icon(
          Icons.check_circle_outline,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        );
      case SyncItemStatus.failed:
        statusIcon = Icon(
          Icons.error_outline,
          size: 18,
          color: Theme.of(context).colorScheme.error,
        );
    }

    final errorText = item.lastError;
    final showError =
        errorText != null && item.status == SyncItemStatus.failed;

    return ListTile(
      leading: statusIcon,
      title: Text(
        '${item.entityType.name.toUpperCase()} · ${item.operation.name}',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tentativas: ${item.attempts} · ${_formatDate(item.updatedAt)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (showError)
            Text(
              _friendlyError(errorText),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
      isThreeLine: showError,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Exibe erro amigável — sem token, URL com segredo, headers ou stack trace.
  String _friendlyError(String raw) {
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Connection refused')) {
      return 'Sem conexao com o servidor.';
    }
    if (raw.contains('401') || raw.contains('403')) {
      return 'Sessao expirada ou sem permissao.';
    }
    if (raw.contains('500') ||
        raw.contains('502') ||
        raw.contains('503')) {
      return 'Erro no servidor. Tente mais tarde.';
    }
    return 'Falha ao sincronizar. Tente novamente.';
  }
}
