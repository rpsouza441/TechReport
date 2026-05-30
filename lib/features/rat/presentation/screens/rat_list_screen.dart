import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_radii.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

import '../../domain/repositories/rat_repository.dart';
import '../../presentation/view_models/rat_form_view_model.dart';
import '../../presentation/view_models/rat_list_view_model.dart';
import 'rat_form_screen.dart';

class RatListScreen extends StatefulWidget {
  const RatListScreen({
    super.key,
    required this.assinaturaRepository,
    required this.localSignatureAssetStore,
    required this.ratPdfShareService,
    required this.viewModel,
    required this.ratRepository,
    required this.shareRatLocally,
    this.remoteSession,
    this.enqueueRatSync,
    this.processSyncQueue,
    this.downloadRemoteRats,
    this.embedded = false,
  });

  final AssinaturaRepository assinaturaRepository;
  final LocalSignatureAssetStore localSignatureAssetStore;
  final RatPdfShareService ratPdfShareService;
  final RatListViewModel viewModel;
  final RatRepository ratRepository;
  final ShareRatLocally shareRatLocally;
  final SessaoRemota? remoteSession;
  final EnqueueRatSync? enqueueRatSync;
  final ProcessSyncQueue? processSyncQueue;
  final DownloadRemoteRats? downloadRemoteRats;
  final bool embedded;

  @override
  State<RatListScreen> createState() => _RatListScreenState();
}

class _RatListScreenState extends State<RatListScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final body = _buildBody(context);

        if (widget.embedded) {
          return Stack(
            children: [
              body,
              Positioned(
                right: MetricSlateSpacing.md,
                bottom: MetricSlateSpacing.md,
                child: FloatingActionButton.extended(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo RAT'),
                ),
              ),
            ],
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Relatórios RAT'),
            actions: [
              if (widget.remoteSession != null)
                IconButton(
                  onPressed: widget.viewModel.isLoading ? null : _syncNow,
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sincronizar',
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: const Text('Novo RAT'),
          ),
          body: body,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.viewModel.errorMessage != null) {
      return TechReportStateView.error(
        message: widget.viewModel.errorMessage!,
        primaryAction: FilledButton(
          onPressed: widget.viewModel.load,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterBar(context),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasActiveFilter =
        widget.viewModel.query.isNotEmpty ||
        widget.viewModel.statusFilter != null;

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
              onChanged: widget.viewModel.setQuery,
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Status do RAT',
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RatStatus?>(
                  isExpanded: true,
                  value: widget.viewModel.statusFilter,
                  hint: const Text('Todos'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(
                      value: RatStatus.draft,
                      child: Text('Rascunho'),
                    ),
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
                  onChanged: widget.viewModel.setStatusFilter,
                ),
              ),
            ),
            if (hasActiveFilter) ...[
              const SizedBox(height: MetricSlateSpacing.sm),
              Wrap(
                spacing: MetricSlateSpacing.xs,
                runSpacing: MetricSlateSpacing.xs,
                children: [
                  if (widget.viewModel.query.isNotEmpty)
                    TechReportStatusChip(
                      label: 'Busca',
                      tone: TechReportStatusTone.info,
                      icon: Icons.search,
                    ),
                  if (widget.viewModel.statusFilter != null)
                    TechReportStatusChip(
                      label: ratStatusLabel(widget.viewModel.statusFilter!),
                      tone: ratStatusTone(widget.viewModel.statusFilter!),
                    ),
                  ActionChip(
                    label: const Text('Limpar'),
                    onPressed: () {
                      widget.viewModel.setQuery('');
                      widget.viewModel.setStatusFilter(null);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final rats = widget.viewModel.filteredRats;

    if (rats.isEmpty) {
      final hasActiveFilter =
          widget.viewModel.query.isNotEmpty ||
          widget.viewModel.statusFilter != null;

      return TechReportStateView.empty(
        message: hasActiveFilter
            ? 'Nenhum RAT corresponde ao filtro atual.'
            : 'Nenhum RAT cadastrado ainda.',
        primaryAction: hasActiveFilter
            ? TextButton(
                onPressed: () {
                  widget.viewModel.setQuery('');
                  widget.viewModel.setStatusFilter(null);
                },
                child: const Text('Limpar filtros'),
              )
            : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        MetricSlateSpacing.md,
        MetricSlateSpacing.sm,
        MetricSlateSpacing.md,
        88,
      ),
      itemCount: rats.length + 1,
      separatorBuilder: (_, index) {
        if (index == 0) {
          return const SizedBox(height: MetricSlateSpacing.sm);
        }
        return const SizedBox(height: MetricSlateSpacing.sm);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${rats.length} ${rats.length == 1 ? 'relatório' : 'relatórios'}',
            style: Theme.of(context).textTheme.labelLarge,
          );
        }

        final rat = rats[index - 1];
        return _RatListItemCard(
          rat: rat,
          hasSignature: widget.viewModel.hasSignature(rat.id),
          onTap: () => _openEdit(rat),
        );
      },
    );
  }

  Future<void> _openCreate() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RatFormScreen(
          viewModel: RatFormViewModel(
            assinaturaRepository: widget.assinaturaRepository,
            localSignatureAssetStore: widget.localSignatureAssetStore,
            ratPdfShareService: widget.ratPdfShareService,
            ratRepository: widget.ratRepository,
            shareRatLocally: widget.shareRatLocally,
            remoteSession: widget.remoteSession,
            enqueueRatSync: widget.enqueueRatSync,
            processSyncQueue: widget.processSyncQueue,
            downloadRemoteRats: widget.downloadRemoteRats,
          ),
        ),
      ),
    );

    if (result == true) {
      await widget.viewModel.load();
    }
  }

  Future<void> _openEdit(Rat rat) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RatFormScreen(
          viewModel: RatFormViewModel(
            assinaturaRepository: widget.assinaturaRepository,
            localSignatureAssetStore: widget.localSignatureAssetStore,
            ratPdfShareService: widget.ratPdfShareService,
            ratRepository: widget.ratRepository,
            shareRatLocally: widget.shareRatLocally,
            initialRat: rat,
            remoteSession: widget.remoteSession,
            enqueueRatSync: widget.enqueueRatSync,
            processSyncQueue: widget.processSyncQueue,
            downloadRemoteRats: widget.downloadRemoteRats,
          ),
        ),
      ),
    );

    if (result == true) {
      await widget.viewModel.load();
    }
  }

  Future<void> _syncNow() async {
    final session = widget.remoteSession;
    final processSyncQueue = widget.processSyncQueue;
    final downloadRemoteRats = widget.downloadRemoteRats;

    if (session == null ||
        !session.hasCompanyContext ||
        processSyncQueue == null) {
      return;
    }

    final empresaId = session.empresaId!;
    final papel =
        session.papelEmpresa?.name ?? session.papelGlobal?.name ?? 'unknown';

    await processSyncQueue.call(
      empresaId: empresaId,
      usuarioId: session.usuarioId,
      retryFailed: true,
    );
    await downloadRemoteRats?.call(
      empresaId: empresaId,
      usuarioId: session.usuarioId,
      papel: papel,
    );
    await widget.viewModel.load();
  }
}

class _RatListItemCard extends StatelessWidget {
  const _RatListItemCard({
    required this.rat,
    required this.hasSignature,
    required this.onTap,
  });

  final Rat rat;
  final bool hasSignature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
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
                      Text(
                        rat.clienteNome,
                        style: theme.textTheme.titleMedium,
                      ),
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
                    ],
                  ),
                ),
                if (hasSignature)
                  Padding(
                    padding: const EdgeInsets.only(left: MetricSlateSpacing.xs),
                    child: Icon(
                      Icons.draw_outlined,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
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
                  label: _syncLabel(rat.syncStatus),
                  tone: _syncTone(rat.syncStatus),
                  icon: _syncIcon(rat.syncStatus),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _syncLabel(RatSyncStatus status) {
  return switch (status) {
    RatSyncStatus.localOnly => 'Local',
    RatSyncStatus.pendingSync => 'Pendente',
    RatSyncStatus.synced => 'Sincronizado',
    RatSyncStatus.syncError => 'Erro de sync',
  };
}

TechReportStatusTone _syncTone(RatSyncStatus status) {
  return switch (status) {
    RatSyncStatus.localOnly => TechReportStatusTone.neutral,
    RatSyncStatus.pendingSync => TechReportStatusTone.warning,
    RatSyncStatus.synced => TechReportStatusTone.success,
    RatSyncStatus.syncError => TechReportStatusTone.error,
  };
}

IconData? _syncIcon(RatSyncStatus status) {
  return switch (status) {
    RatSyncStatus.localOnly => Icons.smartphone_outlined,
    RatSyncStatus.pendingSync => Icons.schedule,
    RatSyncStatus.synced => Icons.cloud_done_outlined,
    RatSyncStatus.syncError => Icons.error_outline,
  };
}
