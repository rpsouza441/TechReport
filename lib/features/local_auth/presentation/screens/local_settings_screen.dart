import 'package:flutter/material.dart';
import 'package:techreport/app/theme/app_theme_mode.dart';
import 'package:techreport/app/theme/app_theme_variant.dart';
import 'package:techreport/app/theme/app_theme_view_model.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_service.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_backup.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_backup.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_data_import.dart';
import 'package:techreport/features/local_auth/presentation/screens/local_data_import_screen.dart';
import 'package:techreport/features/local_auth/presentation/screens/local_data_info_screen.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';
import 'package:techreport/features/local_auth/presentation/view_models/local_data_import_view_model.dart';
import 'package:techreport/features/local_auth/presentation/widgets/local_info_card.dart';
import 'package:techreport/features/rat/domain/permissions/rat_permissions.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/services/rat_sync_coordinator.dart';
import 'package:techreport/features/rat/domain/usecases/restore_rat.dart';
import 'package:techreport/features/rat/presentation/screens/trash_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/trash_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/trash_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_confirmation_dialog.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_section_header.dart';

class LocalAdministrationScreen extends StatefulWidget {
  const LocalAdministrationScreen({
    super.key,
    required this.appSessionViewModel,
    required this.themeViewModel,
    required this.onSwitchMode,
    required this.ratRepository,
    required this.localBackupService,
    required this.localBackupParser,
    required this.localDataImportParser,
    required this.applyLocalDataImport,
    required this.previewLocalDataImport,
    this.onOpenProfile,
    this.onOpenRats,
  });

  final AppSessionViewModel appSessionViewModel;
  final AppThemeViewModel themeViewModel;
  final Future<void> Function() onSwitchMode;
  final RatRepository ratRepository;
  final LocalBackupService localBackupService;
  final LocalBackupParser localBackupParser;
  final LocalDataImportParser localDataImportParser;
  final ApplyLocalDataImport applyLocalDataImport;
  final PreviewLocalDataImport previewLocalDataImport;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenRats;

  @override
  State<LocalAdministrationScreen> createState() =>
      _LocalAdministrationScreenState();
}

class _LocalAdministrationScreenState extends State<LocalAdministrationScreen> {
  DateTime? _latestBackupAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administração local')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(MetricSlateSpacing.lg),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Gerencie somente os dados deste dispositivo. '
                  'Nada aqui depende do servidor.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: MetricSlateSpacing.lg),
                _section('Backup e dados'),
                _card(
                  icon: Icons.info_outline,
                  title: 'Informações dos dados',
                  body: 'Veja contagens e informações seguras do banco local.',
                  onTap: _openDataInfo,
                ),
                _card(
                  icon: Icons.file_upload_outlined,
                  title: 'Exportar backup',
                  body: 'Salve RATs ativas e itens da lixeira.',
                  onTap: _openExport,
                ),
                _card(
                  icon: Icons.file_download_outlined,
                  title: 'Restaurar backup',
                  body: 'Revise e restaure um backup deste dispositivo.',
                  onTap: _openImport,
                ),
                _section('Perfil e conteúdo'),
                _card(
                  icon: Icons.person_outline,
                  title: 'Meu perfil',
                  body: 'Atualize os dados usados nos RATs deste dispositivo.',
                  onTap: () => _returnTo(widget.onOpenProfile),
                ),
                _card(
                  icon: Icons.description_outlined,
                  title: 'RATs',
                  body: 'Volte para a lista de RATs locais.',
                  onTap: () => _returnTo(widget.onOpenRats),
                ),
                _card(
                  icon: Icons.delete_outline,
                  title: 'Lixeira',
                  body:
                      'Consulte e restaure RATs removidas da lista principal.',
                  onTap: _openTrash,
                ),
                _section('Aparência'),
                _card(
                  icon: Icons.palette_outlined,
                  title: 'Tema do app',
                  body: 'Escolha o modo e a paleta de cores.',
                  trailing: Text(
                    widget.themeViewModel.currentVariant.displayName,
                  ),
                  onTap: _openThemeSelector,
                ),
                _section('Modo de operação'),
                _card(
                  icon: Icons.cloud_outlined,
                  title: 'Trocar para modo empresa',
                  body: 'Conecte-se ao servidor da empresa.',
                  onTap: _confirmSwitchMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(
      top: MetricSlateSpacing.md,
      bottom: MetricSlateSpacing.sm,
    ),
    child: TechReportSectionHeader(title: title, padding: EdgeInsets.zero),
  );

  Widget _card({
    required IconData icon,
    required String title,
    required String body,
    required VoidCallback onTap,
    Widget? trailing,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: MetricSlateSpacing.sm),
    child: LocalInfoCard(
      icon: icon,
      title: title,
      body: body,
      trailing: trailing,
      showChevron: trailing == null,
      onTap: onTap,
    ),
  );

  void _returnTo(VoidCallback? callback) {
    Navigator.of(context).pop();
    callback?.call();
  }

  void _openTrash() {
    final coordinator = RatSyncCoordinator.local(
      restoreRat: RestoreRat(
        ratRepository: widget.ratRepository,
        permissions: const RatPermissions(),
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrashScreen(
          viewModel: TrashViewModel(
            ratRepository: widget.ratRepository,
            syncCoordinator: coordinator,
            scope: const LocalTrashScope(),
            session: null,
          ),
        ),
      ),
    );
  }

  void _openDataInfo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalDataInfoScreen(
          ratRepository: widget.ratRepository,
          latestBackupAt: _latestBackupAt,
        ),
      ),
    );
  }

  Future<void> _openExport() async {
    try {
      final path = await widget.localBackupService.saveBackupToDevice();
      if (!mounted || path == null) return;
      setState(() => _latestBackupAt = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup exportado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível exportar o backup.')),
      );
    }
  }

  void _openImport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalDataImportScreen(
          viewModel: LocalDataImportViewModel(
            previewLocalBackup: PreviewLocalBackup(
              parser: widget.localBackupParser,
            ),
            applyLocalBackup: ApplyLocalBackup(
              parser: widget.localBackupParser,
              applyLocalDataImport: widget.applyLocalDataImport,
            ),
            localDataImportParser: widget.localDataImportParser,
            previewLocalDataImport: widget.previewLocalDataImport,
            applyLocalDataImport: widget.applyLocalDataImport,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSwitchMode() async {
    final navigator = Navigator.of(context);
    final confirmed = await showTechReportConfirmationDialog(
      context: context,
      title: 'Trocar para modo empresa?',
      message: 'Seus RATs locais permanecem neste dispositivo.',
      confirmLabel: 'Trocar para modo empresa',
      cancelLabel: 'Continuar no modo local',
    );
    if (!confirmed) return;
    navigator.pop();
    await widget.onSwitchMode();
  }

  void _openThemeSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _ThemeSelectorSheet(viewModel: widget.themeViewModel),
    );
  }
}

class _ThemeSelectorSheet extends StatelessWidget {
  const _ThemeSelectorSheet({required this.viewModel});

  final AppThemeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MetricSlateSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Aparência', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: MetricSlateSpacing.md),
            for (final mode in AppThemeModePreference.values)
              RadioListTile<AppThemeModePreference>(
                value: mode,
                groupValue: viewModel.currentMode,
                title: Text(mode.label),
                onChanged: (value) {
                  if (value != null) viewModel.setMode(value);
                },
              ),
            const Divider(),
            for (final variant in AppThemeVariant.values)
              RadioListTile<AppThemeVariant>(
                value: variant,
                groupValue: viewModel.currentVariant,
                title: Text(variant.displayName),
                subtitle: Text(variant.description),
                onChanged: (value) {
                  if (value != null) viewModel.setVariant(value);
                },
              ),
          ],
        ),
      ),
    );
  }
}
