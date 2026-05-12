import 'package:flutter/material.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';

import '../../domain/entities/rat.dart';
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
    this.onSignOut,
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
  final Future<void> Function()? onSignOut;

  @override
  State<RatListScreen> createState() => _RatListScreenState();
}

class _RatListScreenState extends State<RatListScreen> {
  bool _isSigningOut = false;

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
              if (widget.remoteSession != null)
                IconButton(
                  onPressed: _isSigningOut ? null : _signOut,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sair',
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: const Text('Novo RAT'),
          ),
          body: Builder(
            builder: (context) {
              if (widget.viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (widget.viewModel.errorMessage != null) {
                return Center(child: Text(widget.viewModel.errorMessage!));
              }

              if (widget.viewModel.isEmpty) {
                return const Center(
                  child: Text('Nenhum RAT cadastrado ainda.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.viewModel.rats.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final rat = widget.viewModel.rats[index];
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
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
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
            },
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

    if (session == null || processSyncQueue == null) {
      return;
    }

    await processSyncQueue.call(
      empresaId: session.empresaId,
      usuarioId: session.usuarioId,
      retryFailed: true,
    );
    await downloadRemoteRats?.call(empresaId: session.empresaId);
    await widget.viewModel.load();
  }

  Future<void> _signOut() async {
    final onSignOut = widget.onSignOut;
    if (onSignOut == null) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    await onSignOut();
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
