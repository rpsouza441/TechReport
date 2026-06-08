import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:techreport/app/theme/app_theme_view_model.dart';
import 'package:techreport/app/theme/metric_slate_radii.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_service.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_data_export_share_service.dart';
import 'package:techreport/features/local_auth/domain/entities/tecnico_local.dart';
import 'package:techreport/features/local_auth/domain/repositories/tecnico_local_repository.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/update_tecnico_local.dart';
import 'package:techreport/features/local_auth/presentation/screens/local_settings_screen.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart' as domain;
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';
import 'package:techreport/features/rat/presentation/screens/rat_form_screen.dart';
import 'package:techreport/features/rat/presentation/screens/rat_pdf_preview_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_form_view_model.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_view_model.dart';
import 'package:techreport/features/rat/presentation/widgets/rat_list_filter_bar.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_mode_title.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ratListViewModel, widget.themeViewModel, widget.viewModel]),
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
        return _ProfileTab(
          tecnicoLocalRepository: widget.tecnicoLocalRepository,
          viewModel: widget.viewModel,
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
            TextButton(
              onPressed: _lockLocal,
              child: const Text('Bloquear'),
            ),
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
              return TechReportCard(
                onTap: () => _openEdit(context, rat),
                child: InkWell(
                  borderRadius: BorderRadius.circular(MetricSlateRadii.md),
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
                                const SizedBox(
                                  height: MetricSlateSpacing.xxs,
                                ),
                                Text(
                                  rat.numero,
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
                                Icon(
                                  Icons.draw_outlined,
                                  size: 22,
                                  color: theme.colorScheme.primary,
                                ),
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                tooltip: 'Prévia PDF',
                                onPressed: () => _openPdfPreview(context, rat),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: MetricSlateSpacing.sm),
                      Wrap(
                        spacing: MetricSlateSpacing.sm,
                        runSpacing: MetricSlateSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TechReportStatusChip(
                            label: ratStatusLabel(rat.status),
                            tone: ratStatusTone(rat.status),
                          ),
                          Text(
                            _formatDate(rat.updatedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> _openPdfPreview(
    BuildContext context,
    domain.Rat rat,
  ) async {
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

// ─── Meu Perfil tab ──────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    required this.tecnicoLocalRepository,
    required this.viewModel,
  });

  final TecnicoLocalRepository tecnicoLocalRepository;
  final AppSessionViewModel viewModel;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  TecnicoLocal? _tecnico;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isEditing = false;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTecnico();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadTecnico() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tecnico = await widget.tecnicoLocalRepository.getCurrent();
      setState(() {
        _tecnico = tecnico;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Não foi possível carregar o perfil.';
        _isLoading = false;
      });
    }
  }

  void _startEditing() {
    _nomeController.text = _tecnico?.nome ?? '';
    _emailController.text = _tecnico?.email ?? '';
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveEditing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final update = UpdateTecnicoLocal(widget.tecnicoLocalRepository);
      await update.call(
        nome: _nomeController.text,
        email: _emailController.text,
      );
      await _loadTecnico();
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado.')),
        );
      }
    } catch (_) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Não foi possível salvar. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const TechReportModeTitle(modeLabel: 'Modo Local'),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar perfil',
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _tecnico == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: MetricSlateSpacing.md),
            FilledButton(
              onPressed: _loadTecnico,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MetricSlateSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            TechReportErrorBanner(message: _errorMessage!),
            const SizedBox(height: MetricSlateSpacing.md),
          ],
          if (_isEditing) _buildEditForm() else _buildReadOnlyProfile(),
        ],
      ),
    );
  }

  Widget _buildReadOnlyProfile() {
    final t = _tecnico;
    if (t == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileCard(
          icon: Icons.person_outline,
          title: 'Nome',
          value: t.nome,
        ),
        const SizedBox(height: MetricSlateSpacing.sm),
        _ProfileCard(
          icon: Icons.mail_outline,
          title: 'E-mail',
          value: t.email,
        ),
        if (t.telefone != null && t.telefone!.isNotEmpty) ...[
          const SizedBox(height: MetricSlateSpacing.sm),
          _ProfileCard(
            icon: Icons.phone_outlined,
            title: 'Telefone',
            value: t.telefone!,
          ),
        ],
        if (t.empresaNome != null && t.empresaNome!.isNotEmpty) ...[
          const SizedBox(height: MetricSlateSpacing.sm),
          _ProfileCard(
            icon: Icons.business_outlined,
            title: 'Empresa',
            value: t.empresaNome!,
          ),
        ],
        const SizedBox(height: MetricSlateSpacing.sm),
        _ProfileCard(
          icon: t.pinConfigured ? Icons.lock_outlined : Icons.lock_open_outlined,
          title: 'PIN',
          value: t.pinConfigured ? 'Configurado' : 'Não configurado',
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return TechReportCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TechReportFormHeader(
              icon: Icons.edit_outlined,
              title: 'Editar perfil',
              subtitle: 'Altere seus dados de identificação local.',
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            TextFormField(
              controller: _nomeController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o nome.' : null,
            ),
            const SizedBox(height: MetricSlateSpacing.md),
            TextFormField(
              controller: _emailController,
              enabled: !_isSaving,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o e-mail.';
                }
                if (!v.contains('@')) {
                  return 'Informe um e-mail válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            FilledButton(
              onPressed: _isSaving ? null : _saveEditing,
              child: Text(_isSaving ? 'Salvando...' : 'Salvar'),
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            OutlinedButton(
              onPressed: _isSaving ? null : _cancelEditing,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TechReportCard(
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
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

class LocalPinScreen extends StatefulWidget {
  const LocalPinScreen({
    super.key,
    required this.hasPin,
    required this.viewModel,
  });

  final bool hasPin;
  final AppSessionViewModel viewModel;

  @override
  State<LocalPinScreen> createState() => _LocalPinScreenState();
}

class _LocalPinScreenState extends State<LocalPinScreen> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.hasPin ? 'Trocar PIN' : 'Criar PIN';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: _isSubmitting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              title,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.hasPin
                  ? 'Informe o PIN atual. Deixe o novo PIN vazio para removê-lo.'
                  : 'Crie um PIN de 4 a 8 dígitos para proteger o modo local.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.hasPin) ...[
              TextField(
                controller: _currentPinController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'PIN atual',
                  prefixIcon: Icon(Icons.lock_outline),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _newPinController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Novo PIN',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmationController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Confirmação do novo PIN',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.viewModel.changePin(
      currentPin: widget.hasPin ? _currentPinController.text : null,
      newPin: _newPinController.text,
      confirmation: _confirmationController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage =
          widget.viewModel.errorMessage ?? 'Não foi possível alterar o PIN.';
    });
  }
}
