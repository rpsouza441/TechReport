import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/services/rat_sync_coordinator.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';

import '../../domain/repositories/rat_repository.dart';
import '../../presentation/view_models/rat_form_view_model.dart';
import '../../presentation/view_models/rat_list_view_model.dart';
import '../widgets/rat_list_item_card.dart';
import '../widgets/rat_list_filter_bar.dart';
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
    this.supabaseClientFactory,
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
  final SupabaseClientFactory? supabaseClientFactory;
  final bool embedded;

  @override
  State<RatListScreen> createState() => _RatListScreenState();
}

class _RatListScreenState extends State<RatListScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      widget.viewModel.loadMore();
    }
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
    return RatListFilterBar(viewModel: widget.viewModel);
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
          child: RefreshIndicator(
            onRefresh: _syncNow,
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                MetricSlateSpacing.md,
                0,
                MetricSlateSpacing.md,
                88,
              ),
              itemCount: rats.length + (widget.viewModel.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  const SizedBox(height: MetricSlateSpacing.sm),
              itemBuilder: (context, index) {
                if (index >= rats.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final rat = rats[index];
                return RatListItemCard(
                  rat: rat,
                  hasSignature: widget.viewModel.hasSignature(rat.id),
                  onTap: () => _openEdit(rat),
                  onPreviewPdf: () => _openPdfPreview(rat),
                  showSyncStatus: true,
                );
              },
            ),
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
            enqueueAssinaturaSync: widget.enqueueAssinaturaSync,
            syncCoordinator: _syncCoordinator(),
            downloadRemoteRats: widget.downloadRemoteRats,
            supabaseClientFactory: widget.supabaseClientFactory,
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
            enqueueAssinaturaSync: widget.enqueueAssinaturaSync,
            syncCoordinator: _syncCoordinator(),
            downloadRemoteRats: widget.downloadRemoteRats,
            supabaseClientFactory: widget.supabaseClientFactory,
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
      enqueueAssinaturaSync: widget.enqueueAssinaturaSync,
      syncCoordinator: _syncCoordinator(),
      downloadRemoteRats: widget.downloadRemoteRats,
      supabaseClientFactory: widget.supabaseClientFactory,
    );

    try {
      await viewModel.loadSignatureStatus();
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
            assinaturaPendente: previewData.assinaturaPendente,
            empresaNome: previewData.empresaNome,
            tecnicoNome: previewData.tecnicoNome,
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
    } finally {
      viewModel.dispose();
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

  RatSyncCoordinator? _syncCoordinator() {
    final enqueueRatSync = widget.enqueueRatSync;
    final enqueueAssinaturaSync = widget.enqueueAssinaturaSync;
    final processSyncQueue = widget.processSyncQueue;

    if (enqueueRatSync == null ||
        enqueueAssinaturaSync == null ||
        processSyncQueue == null) {
      return null;
    }

    return RatSyncCoordinator(
      enqueueRatSync: enqueueRatSync,
      enqueueAssinaturaSync: enqueueAssinaturaSync,
      processSyncQueue: processSyncQueue,
    );
  }
}
