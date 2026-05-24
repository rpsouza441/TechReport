import 'package:flutter/material.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';

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
        if (widget.embedded) {
          return Stack(
            children: [
              _buildBody(context),
              Positioned(
                right: 16,
                bottom: 16,
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
            title: const Text('RATs'),
            actions: [
              if (widget.remoteSession != null)
                IconButton(
                  onPressed: _syncNow,
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
          body: _buildBody(context),
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
      children: [
        _buildFilterBar(),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar cliente ou descrição',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: widget.viewModel.setQuery,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<RatStatus?>(
            value: widget.viewModel.statusFilter,
            hint: const Text('Status'),
            underline: const SizedBox.shrink(),
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
            onChanged: widget.viewModel.setStatusFilter,
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: rats.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rat = rats[index];
        final hasSignature = widget.viewModel.hasSignature(rat.id);
        return Card(
          child: ListTile(
            title: Row(
              children: [
                Expanded(child: Text(rat.clienteNome)),
                if (hasSignature) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.draw,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
            subtitle: Text(rat.descricao),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(rat.status.name),
                const SizedBox(height: 4),
                Text(
                  _syncLabel(rat.syncStatus),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _syncColor(context, rat.syncStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            onTap: () => _openEdit(rat),
          ),
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

  Color _syncColor(BuildContext context, RatSyncStatus status) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case RatSyncStatus.localOnly:
        return colorScheme.outline;
      case RatSyncStatus.pendingSync:
        return colorScheme.tertiary;
      case RatSyncStatus.synced:
        return colorScheme.primary;
      case RatSyncStatus.syncError:
        return colorScheme.error;
    }
  }

  String _syncLabel(RatSyncStatus status) {
    switch (status) {
      case RatSyncStatus.localOnly:
        return 'Local';
      case RatSyncStatus.pendingSync:
        return 'Pendente';
      case RatSyncStatus.synced:
        return 'Sincronizado';
      case RatSyncStatus.syncError:
        return 'Erro de sync';
    }
  }
}
