import 'package:flutter/material.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_data_export_share_service.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_data_import.dart';
import 'package:techreport/features/local_auth/presentation/screens/local_data_import_screen.dart';
import 'package:techreport/features/local_auth/presentation/view_models/local_data_import_view_model.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart' as domain;
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';
import 'package:techreport/features/rat/presentation/screens/rat_form_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_form_view_model.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_view_model.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

import '../view_models/app_session_view_model.dart';

class LocalHomeScreen extends StatefulWidget {
  const LocalHomeScreen({
    super.key,
    required this.assinaturaRepository,
    required this.applyLocalDataImport,
    required this.localDataImportParser,
    required this.localDataExportShareService,
    required this.localSignatureAssetStore,
    required this.previewLocalDataImport,
    required this.ratPdfShareService,
    required this.viewModel,
    required this.ratRepository,
    required this.shareRatLocally,
    required this.onLocalLocked,
    required this.onSwitchMode,
  });

  final AssinaturaRepository assinaturaRepository;
  final ApplyLocalDataImport applyLocalDataImport;
  final LocalDataImportParser localDataImportParser;
  final LocalDataExportShareService localDataExportShareService;
  final LocalSignatureAssetStore localSignatureAssetStore;
  final PreviewLocalDataImport previewLocalDataImport;
  final RatPdfShareService ratPdfShareService;
  final AppSessionViewModel viewModel;
  final RatRepository ratRepository;
  final ShareRatLocally shareRatLocally;
  final VoidCallback onLocalLocked;
  final Future<void> Function() onSwitchMode;

  @override
  State<LocalHomeScreen> createState() => _LocalHomeScreenState();
}

class _LocalHomeScreenState extends State<LocalHomeScreen> {
  late final RatListViewModel _ratListViewModel;

  @override
  void initState() {
    super.initState();

    _ratListViewModel = RatListViewModel(
      assinaturaRepository: widget.assinaturaRepository,
      ratRepository: widget.ratRepository,
      scope: const RatListScope.local(),
    );
    _ratListViewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _ratListViewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tech Report'),
            actions: [
              if (widget.viewModel.pinConfigured)
                TextButton(
                  onPressed: _lockLocal,
                  child: const Text('Bloquear'),
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seus RATs locais',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie, acompanhe e edite atendimentos salvos neste dispositivo.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _openCreate,
                          icon: const Icon(Icons.add),
                          label: const Text('Novo RAT'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<_LocalHomeAction>(
                        tooltip: 'Menu local',
                        onSelected: _handleMenuAction,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: _LocalHomeAction.refresh,
                            child: ListTile(
                              leading: Icon(Icons.refresh),
                              title: Text('Atualizar'),
                            ),
                          ),
                          PopupMenuItem(
                            value: _LocalHomeAction.changePin,
                            child: ListTile(
                              leading: const Icon(Icons.pin_outlined),
                              title: Text(
                                widget.viewModel.pinConfigured
                                    ? 'Trocar PIN'
                                    : 'Criar PIN',
                              ),
                            ),
                          ),
                          const PopupMenuItem(
                            value: _LocalHomeAction.export,
                            child: ListTile(
                              leading: Icon(Icons.file_upload_outlined),
                              title: Text('Exportar dados'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: _LocalHomeAction.import,
                            child: ListTile(
                              leading: Icon(Icons.file_download_outlined),
                              title: Text('Importar dados'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: _LocalHomeAction.switchMode,
                            child: ListTile(
                              leading: Icon(Icons.swap_horiz),
                              title: Text('Trocar modo'),
                            ),
                          ),
                        ],
                        child: const IconButton.filledTonal(
                          onPressed: null,
                          icon: Icon(Icons.more_vert),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (_ratListViewModel.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (_ratListViewModel.errorMessage != null) {
                          return Center(
                            child: Text(_ratListViewModel.errorMessage!),
                          );
                        }

                        if (_ratListViewModel.isEmpty) {
                          return _EmptyRatState(onCreate: _openCreate);
                        }

                        return ListView.separated(
                          itemCount: _ratListViewModel.rats.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final rat = _ratListViewModel.rats[index];
                            final hasSignature = _ratListViewModel.hasSignature(
                              rat.id,
                            );
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
                                        color: theme.colorScheme.primary,
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  rat.descricao,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(ratStatusLabel(rat.status)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(rat.updatedAt),
                                      style: theme.textTheme.bodySmall,
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
                  ),
                ],
              ),
            ),
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
          ),
        ),
      ),
    );

    if (result == true) {
      await _ratListViewModel.load();
    }
  }

  Future<void> _lockLocal() async {
    await widget.viewModel.lock();
    widget.onLocalLocked();
  }

  Future<void> _switchMode() async {
    if (widget.viewModel.pinConfigured) {
      await widget.viewModel.lock();
    }

    await widget.onSwitchMode();
  }

  Future<void> _handleMenuAction(_LocalHomeAction action) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    switch (action) {
      case _LocalHomeAction.refresh:
        await _ratListViewModel.load();
      case _LocalHomeAction.changePin:
        await _showChangePinDialog(context);
      case _LocalHomeAction.export:
        await _showExportOptions(context);
      case _LocalHomeAction.import:
        await _openImport();
      case _LocalHomeAction.switchMode:
        await _switchMode();
    }
  }

  Future<void> _showChangePinDialog(BuildContext parentContext) async {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmationController = TextEditingController();
    final hasPin = widget.viewModel.pinConfigured;
    var isSubmitting = false;
    String? errorMessage;

    final changed = await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              setDialogState(() {
                isSubmitting = true;
              });

              final success = await widget.viewModel.changePin(
                currentPin: hasPin ? currentPinController.text : null,
                newPin: newPinController.text,
                confirmation: confirmationController.text,
              );

              if (!context.mounted) {
                return;
              }

              if (success) {
                Navigator.of(context).pop(true);
                return;
              }

              setDialogState(() {
                isSubmitting = false;
                errorMessage = widget.viewModel.errorMessage;
              });
            }

            return AlertDialog(
              title: Text(hasPin ? 'Trocar PIN' : 'Criar PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPin) ...[
                    TextField(
                      controller: currentPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'PIN atual'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Novo PIN com 4 dígitos',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmationController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmação do novo PIN',
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPinController.dispose();
    newPinController.dispose();
    confirmationController.dispose();

    if (!parentContext.mounted || changed != true) {
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(
      parentContext,
    ).showSnackBar(const SnackBar(content: Text('PIN atualizado.')));
  }

  Future<void> _showExportOptions(BuildContext parentContext) async {
    await showModalBottomSheet<void>(
      context: parentContext,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt_outlined),
                title: const Text('Salvar no dispositivo'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _saveLocalData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share_outlined),
                title: const Text('Compartilhar'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _shareLocalData();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveLocalData() async {
    try {
      final path = await widget.localDataExportShareService
          .saveExportToDevice();
      if (!mounted || path == null) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup salvo: $path')));
    } catch (_) {
      _showExportError();
    }
  }

  Future<void> _shareLocalData() async {
    try {
      await widget.localDataExportShareService.shareExport();
    } catch (_) {
      _showExportError();
    }
  }

  void _showExportError() {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível exportar os dados locais.'),
      ),
    );
  }

  Future<void> _openImport() async {
    final imported = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LocalDataImportScreen(
          viewModel: LocalDataImportViewModel(
            parser: widget.localDataImportParser,
            previewImport: widget.previewLocalDataImport,
            applyImport: widget.applyLocalDataImport,
          ),
        ),
      ),
    );

    if (imported == true) {
      await _ratListViewModel.load();
    }
  }

  Future<void> _openEdit(domain.Rat rat) async {
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
          ),
        ),
      ),
    );

    if (result == true) {
      await _ratListViewModel.load();
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

enum _LocalHomeAction { refresh, changePin, export, import, switchMode }

class _EmptyRatState extends StatelessWidget {
  const _EmptyRatState({required this.onCreate});

  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Nenhum RAT criado ainda',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Comece criando o primeiro atendimento local do dispositivo.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onCreate,
                  child: const Text('Criar primeiro RAT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
