import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_radii.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
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
import 'rat_pdf_preview_screen.dart';

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
    this.enqueueAssinaturaSync,
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
  final EnqueueAssinaturaSync? enqueueAssinaturaSync;
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
          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Novo RAT'),
            ),
            body: body,
          );
        }

        return Scaffold(
          appBar: AppBar(
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
            Wrap(
              spacing: MetricSlateSpacing.sm,
              runSpacing: MetricSlateSpacing.sm,
              children: [
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Status do RAT',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonHideUnderline(
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
                      Divider(height: 1, color: scheme.outline),
                    ],
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: _DateRangeField(
                    dateFrom: widget.viewModel.dateFrom,
                    dateTo: widget.viewModel.dateTo,
                    onChanged: widget.viewModel.setDateRange,
                    onClear: widget.viewModel.clearDateRange,
                  ),
                ),
              ],
            ),
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
          widget.viewModel.statusFilter != null ||
          widget.viewModel.dateFrom != null ||
          widget.viewModel.dateTo != null;

      return TechReportStateView.empty(
        message: hasActiveFilter
            ? 'Nenhum RAT corresponde ao filtro atual.'
            : 'Nenhum RAT cadastrado ainda.',
        primaryAction: hasActiveFilter
            ? TextButton(
                onPressed: widget.viewModel.clearAllFilters,
                child: const Text('Limpar filtros'),
              )
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: MetricSlateSpacing.xs,
            bottom: MetricSlateSpacing.sm,
          ),
          child: Text(
            '${rats.length} ${rats.length == 1 ? 'relatório' : 'relatórios'}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              MetricSlateSpacing.md,
              0,
              MetricSlateSpacing.md,
              88,
            ),
            itemCount: rats.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: MetricSlateSpacing.sm),
            itemBuilder: (context, index) {
              final rat = rats[index];
              return _RatListItemCard(
                rat: rat,
                hasSignature: widget.viewModel.hasSignature(rat.id),
                onTap: () => _openEdit(rat),
                onPreviewPdf: () => _openPdfPreview(rat),
              );
            },
          ),
        ),
      ],
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
            enqueueAssinaturaSync: widget.enqueueAssinaturaSync,
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
            enqueueAssinaturaSync: widget.enqueueAssinaturaSync,
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

  Future<void> _openPdfPreview(Rat rat) async {
    final viewModel = RatFormViewModel(
      assinaturaRepository: widget.assinaturaRepository,
      localSignatureAssetStore: widget.localSignatureAssetStore,
      ratPdfShareService: widget.ratPdfShareService,
      ratRepository: widget.ratRepository,
      shareRatLocally: widget.shareRatLocally,
      initialRat: rat,
      remoteSession: widget.remoteSession,
      enqueueRatSync: widget.enqueueRatSync,
      enqueueAssinaturaSync: widget.enqueueAssinaturaSync,
      processSyncQueue: widget.processSyncQueue,
      downloadRemoteRats: widget.downloadRemoteRats,
    );

    final previewData = await viewModel.prepareForPdfPreview(persist: false);
    if (!mounted || previewData == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RatPdfPreviewScreen(
          rat: previewData.rat,
          signatureBytes: previewData.signatureBytes,
          onShare: () async {
            final ok = await viewModel.sharePdf();
            if (!mounted) return;
            if (ok) {
              messenger.showSnackBar(
                const SnackBar(content: Text('PDF pronto para envio.')),
              );
            } else if (viewModel.errorMessage != null) {
              messenger.showSnackBar(
                SnackBar(content: Text(viewModel.errorMessage!)),
              );
            }
          },
          onSave: () async {
            final ok = await viewModel.savePdf();
            if (!mounted) return;
            if (ok) {
              messenger.showSnackBar(
                const SnackBar(content: Text('PDF salvo no dispositivo.')),
              );
            } else if (viewModel.errorMessage != null) {
              messenger.showSnackBar(
                SnackBar(content: Text(viewModel.errorMessage!)),
              );
            }
          },
        ),
      ),
    );
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

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.dateFrom,
    required this.dateTo,
    required this.onChanged,
    required this.onClear,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final void Function({DateTime? from, DateTime? to}) onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasRange = dateFrom != null || dateTo != null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Período',
        isDense: true,
        suffixIcon: hasRange
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
                padding: EdgeInsets.zero,
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Data de inicio: ${dateFrom != null ? _fmt(dateFrom!) : 'nao definida'}',
              button: true,
              child: InkWell(
                onTap: () => _pickDate(context, isFrom: true),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    dateFrom != null ? _fmt(dateFrom!) : 'De',
                    style: TextStyle(
                      color: dateFrom != null
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text('—'),
          const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              label: 'Data de fim: ${dateTo != null ? _fmt(dateTo!) : 'nao definida'}',
              button: true,
              child: InkWell(
                onTap: () => _pickDate(context, isFrom: false),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    dateTo != null ? _fmt(dateTo!) : 'Ate',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: dateTo != null
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final initial = isFrom ? (dateFrom ?? DateTime.now()) : (dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;

    if (isFrom) {
      final effectiveTo = dateTo;
      if (effectiveTo != null && picked.isAfter(effectiveTo)) {
        onChanged(from: effectiveTo, to: picked);
      } else {
        onChanged(from: picked, to: effectiveTo);
      }
    } else {
      final effectiveFrom = dateFrom;
      if (effectiveFrom != null && picked.isBefore(effectiveFrom)) {
        onChanged(from: picked, to: effectiveFrom);
      } else {
        onChanged(from: effectiveFrom, to: picked);
      }
    }
  }
}

class _RatListItemCard extends StatelessWidget {
  const _RatListItemCard({
    required this.rat,
    required this.hasSignature,
    required this.onTap,
    required this.onPreviewPdf,
  });

  final Rat rat;
  final bool hasSignature;
  final VoidCallback onTap;
  final VoidCallback onPreviewPdf;

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
