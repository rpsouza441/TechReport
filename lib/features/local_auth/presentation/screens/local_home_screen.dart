import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:techreport/app/theme/app_theme_view_model.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_service.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_data_export_share_service.dart';
import 'package:techreport/features/local_auth/domain/repositories/tecnico_local_repository.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_data_import.dart';
import 'package:techreport/features/local_auth/presentation/screens/local_profile_screen.dart';
import 'package:techreport/features/local_auth/presentation/screens/local_settings_screen.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart' as domain;
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/rat/presentation/screens/rat_form_screen.dart';
import 'package:techreport/features/rat/presentation/screens/rat_pdf_preview_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_form_view_model.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_view_model.dart';
import 'package:techreport/features/rat/presentation/widgets/rat_list_item_card.dart';
import 'package:techreport/features/rat/presentation/widgets/rat_list_filter_bar.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_mode_title.dart';

enum _LocalTab { rats, profile }

class LocalHomeScreen extends StatefulWidget {
  const LocalHomeScreen({
    super.key,
    required this.assinaturaRepository,
    required this.applyLocalDataImport,
    required this.localBackupParser,
    required this.localBackupService,
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
    required this.themeViewModel,
    required this.tecnicoLocalRepository,
  });

  final AssinaturaRepository assinaturaRepository;
  final ApplyLocalDataImport applyLocalDataImport;
  final LocalBackupParser localBackupParser;
  final LocalBackupService localBackupService;
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
  final AppThemeViewModel themeViewModel;
  final TecnicoLocalRepository tecnicoLocalRepository;

  @override
  State<LocalHomeScreen> createState() => _LocalHomeScreenState();
}

class _LocalHomeScreenState extends State<LocalHomeScreen> {
  late final RatListViewModel _ratListViewModel;
  late final ProfileEditingNotifier _profileEditingNotifier;
  _LocalTab _selectedTab = _LocalTab.rats;

  @override
  void initState() {
    super.initState();

    _ratListViewModel = RatListViewModel(
      assinaturaRepository: widget.assinaturaRepository,
      ratRepository: widget.ratRepository,
      scope: const RatListScope.local(),
    );
    _ratListViewModel.load();

    _profileEditingNotifier = ProfileEditingNotifier();
  }

  @override
  void dispose() {
    _ratListViewModel.dispose();
    _profileEditingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _ratListViewModel,
        _profileEditingNotifier,
        widget.themeViewModel,
        widget.viewModel,
      ]),
      builder: (context, _) {
        return Scaffold(
          body: _buildBody(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab.index,
            onDestinationSelected: (index) {
              setState(() {
                _selectedTab = _LocalTab.values[index];
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: 'RATs',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Meu perfil',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case _LocalTab.rats:
        return _RatsTab(
          ratListViewModel: _ratListViewModel,
          viewModel: widget.viewModel,
          assinaturaRepository: widget.assinaturaRepository,
          localBackupParser: widget.localBackupParser,
          localBackupService: widget.localBackupService,
          localDataImportParser: widget.localDataImportParser,
          localSignatureAssetStore: widget.localSignatureAssetStore,
          previewLocalDataImport: widget.previewLocalDataImport,
          applyLocalDataImport: widget.applyLocalDataImport,
          ratPdfShareService: widget.ratPdfShareService,
          ratRepository: widget.ratRepository,
          shareRatLocally: widget.shareRatLocally,
          onLocalLocked: widget.onLocalLocked,
          onSwitchMode: widget.onSwitchMode,
          themeViewModel: widget.themeViewModel,
          onNavigateToSettings: () => _navigateToSettings(context),
        );

      case _LocalTab.profile:
        return LocalProfileScreen(
          appSessionViewModel: widget.viewModel,
          tecnicoLocalRepository: widget.tecnicoLocalRepository,
          editingNotifier: _profileEditingNotifier,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const TechReportModeTitle(modeLabel: 'Modo Local'),
            actions: [
              if (!_profileEditingNotifier.isEditing &&
                  !_profileEditingNotifier.isLoading)
                IconButton(
                  onPressed: () => _profileEditingNotifier.setEditing(true),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar perfil',
                ),
            ],
          ),
        );
    }
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocalSettingsScreen(
          appSessionViewModel: widget.viewModel,
          themeViewModel: widget.themeViewModel,
          onSwitchMode: () async {
            if (widget.viewModel.pinConfigured) {
              await widget.viewModel.lock();
            }
            await widget.onSwitchMode();
          },
          ratRepository: widget.ratRepository,
          localBackupService: widget.localBackupService,
          localBackupParser: widget.localBackupParser,
          localDataImportParser: widget.localDataImportParser,
          applyLocalDataImport: widget.applyLocalDataImport,
          previewLocalDataImport: widget.previewLocalDataImport,
        ),
      ),
    );
  }
}

// ─── RATs tab ────────────────────────────────────────────────────────────────

class _RatsTab extends StatelessWidget {
  const _RatsTab({
    required this.ratListViewModel,
    required this.viewModel,
    required this.assinaturaRepository,
    required this.localBackupParser,
    required this.localBackupService,
    required this.localDataImportParser,
    required this.localSignatureAssetStore,
    required this.previewLocalDataImport,
    required this.applyLocalDataImport,
    required this.ratPdfShareService,
    required this.ratRepository,
    required this.shareRatLocally,
    required this.onLocalLocked,
    required this.onSwitchMode,
    required this.themeViewModel,
    required this.onNavigateToSettings,
  });

  final RatListViewModel ratListViewModel;
  final AppSessionViewModel viewModel;
  final AssinaturaRepository assinaturaRepository;
  final LocalBackupParser localBackupParser;
  final LocalBackupService localBackupService;
  final LocalDataImportParser localDataImportParser;
  final LocalSignatureAssetStore localSignatureAssetStore;
  final PreviewLocalDataImport previewLocalDataImport;
  final ApplyLocalDataImport applyLocalDataImport;
  final RatPdfShareService ratPdfShareService;
  final RatRepository ratRepository;
  final ShareRatLocally shareRatLocally;
  final VoidCallback onLocalLocked;
  final Future<void> Function() onSwitchMode;
  final AppThemeViewModel themeViewModel;
  final VoidCallback onNavigateToSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const TechReportModeTitle(modeLabel: 'Modo Local'),
        actions: [
          if (viewModel.pinConfigured)
            TextButton(onPressed: _lockLocal, child: const Text('Bloquear')),
          IconButton(
            onPressed: onNavigateToSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo RAT'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RatListFilterBar(viewModel: ratListViewModel),
            Expanded(child: _buildRatListContent(context, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildRatListContent(BuildContext context, ThemeData theme) {
    if (ratListViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ratListViewModel.errorMessage != null) {
      return Center(child: Text(ratListViewModel.errorMessage!));
    }

    if (ratListViewModel.isEmpty) {
      return _EmptyRatState(onCreate: () => _openCreate(context));
    }

    final rats = ratListViewModel.filteredRats;
    if (rats.isEmpty) {
      final hasActiveFilter =
          ratListViewModel.query.isNotEmpty ||
          ratListViewModel.statusFilter != null ||
          ratListViewModel.dateFrom != null ||
          ratListViewModel.dateTo != null;

      return TechReportStateView.empty(
        message: hasActiveFilter
            ? 'Nenhum RAT corresponde ao filtro atual.'
            : 'Nenhum RAT cadastrado ainda.',
        primaryAction: hasActiveFilter
            ? TextButton(
                onPressed: ratListViewModel.clearAllFilters,
                child: const Text('Limpar filtros'),
              )
            : null,
      );
    }

    final count = rats.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: MetricSlateSpacing.xs,
            bottom: MetricSlateSpacing.sm,
          ),
          child: Text(
            '$count RAT${count == 1 ? '' : 's'} locais',
            style: theme.textTheme.labelLarge,
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
              final hasSignature = ratListViewModel.hasSignature(rat.id);
              return RatListItemCard(
                rat: rat,
                hasSignature: hasSignature,
                onTap: () => _openEdit(context, rat),
                onPreviewPdf: () => _openPdfPreview(context, rat),
                showSyncStatus: false,
                trailingDate: rat.updatedAt,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _lockLocal() async {
    await viewModel.lock();
    onLocalLocked();
  }

  Future<void> _openCreate(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RatFormScreen(
          viewModel: RatFormViewModel(
            assinaturaRepository: assinaturaRepository,
            localSignatureAssetStore: localSignatureAssetStore,
            ratPdfShareService: ratPdfShareService,
            ratRepository: ratRepository,
            shareRatLocally: shareRatLocally,
          ),
        ),
      ),
    );

    if (result == true) {
      await ratListViewModel.load();
    }
  }

  Future<void> _openEdit(BuildContext context, domain.Rat rat) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RatFormScreen(
          viewModel: RatFormViewModel(
            assinaturaRepository: assinaturaRepository,
            localSignatureAssetStore: localSignatureAssetStore,
            ratPdfShareService: ratPdfShareService,
            ratRepository: ratRepository,
            shareRatLocally: shareRatLocally,
            initialRat: rat,
          ),
        ),
      ),
    );

    if (result == true) {
      await ratListViewModel.load();
    }
  }

  Future<void> _openPdfPreview(BuildContext context, domain.Rat rat) async {
    final navigator = Navigator.of(context);

    final assinaturas = await assinaturaRepository.listByRatId(rat.id);
    assinaturas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final assinatura = assinaturas.isEmpty ? null : assinaturas.first;

    Uint8List? signatureBytes;
    if (assinatura != null) {
      try {
        signatureBytes = await assinaturaRepository.readBytes(assinatura.id);
      } catch (_) {}
    }

    if (!context.mounted) return;

    final shareResult = await shareRatLocally.call(
      ratId: rat.id,
      scope: const RatListScope.local(),
    );

    final canNavigate = context.mounted;
    if (!canNavigate || !shareResult.success) return;

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => RatPdfPreviewScreen(
          rat: shareResult.rat!,
          signatureBytes: signatureBytes,
          onShare: () => ratPdfShareService.share(shareResult),
          onSave: () => ratPdfShareService.exportToDevice(shareResult),
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _EmptyRatState extends StatelessWidget {
  const _EmptyRatState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: MetricSlateSpacing.md),
          Text(
            'Nenhum RAT cadastrado',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: MetricSlateSpacing.xs),
          Text(
            'Comece criando seu primeiro relatório de atendimento.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MetricSlateSpacing.lg),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Novo RAT'),
          ),
        ],
      ),
    );
  }
}
