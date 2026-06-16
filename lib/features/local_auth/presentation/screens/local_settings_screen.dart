import 'package:flutter/material.dart';
import 'package:techreport/app/theme/app_theme_mode.dart';
import 'package:techreport/app/theme/app_theme_variant.dart';
import 'package:techreport/app/theme/app_theme_view_model.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/local_auth/presentation/screens/local_data_import_screen.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';
import 'package:techreport/features/local_auth/presentation/view_models/local_data_import_view_model.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/data/services/local_backup_service.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_backup.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_backup.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_data_import.dart';
import 'package:techreport/features/local_auth/presentation/widgets/local_info_card.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_confirmation_dialog.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_section_header.dart';

class LocalSettingsScreen extends StatelessWidget {
  const LocalSettingsScreen({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações locais')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(MetricSlateSpacing.lg),
          children: [
            Text(
              'Estas opções afetam apenas o modo local. '
              'Seus dados não são sincronizados com o servidor.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            const TechReportSectionHeader(
              title: 'Dados locais',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            LocalInfoCard(
              icon: Icons.file_upload_outlined,
              title: 'Exportar dados',
              body: 'Salve um backup local dos RATs.',
              showChevron: true,
              onTap: () => _openExport(context),
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            LocalInfoCard(
              icon: Icons.file_download_outlined,
              title: 'Importar dados',
              body: 'Restaure RATs de um backup.',
              showChevron: true,
              onTap: () => _openImport(context),
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            const TechReportSectionHeader(
              title: 'Segurança',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            LocalInfoCard(
              icon: Icons.pin_outlined,
              title: appSessionViewModel.pinConfigured
                  ? 'Trocar PIN'
                  : 'Criar PIN',
              body: appSessionViewModel.pinConfigured
                  ? 'Altere ou remova o PIN de bloqueio.'
                  : 'Proteja o modo local com um PIN.',
              showChevron: true,
              onTap: () => _openChangePin(context),
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            const TechReportSectionHeader(
              title: 'Aparência',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            LocalInfoCard(
              icon: Icons.palette_outlined,
              title: 'Tema do app',
              body: 'Escolha a paleta de cores do TechReport.',
              trailing: Text(
                themeViewModel.currentVariant.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onTap: () => _openThemeSelector(context),
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            const TechReportSectionHeader(
              title: 'Modo de operação',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            LocalInfoCard(
              icon: Icons.cloud_outlined,
              title: 'Trocar para modo empresa',
              body: 'Conecte-se ao servidor da empresa.',
              showChevron: true,
              onTap: () => _confirmSwitchMode(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openChangePin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ChangePinScreen(viewModel: appSessionViewModel),
      ),
    );
  }

  void _openThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ThemeSelectorSheet(
        currentMode: themeViewModel.currentMode,
        currentVariant: themeViewModel.currentVariant,
        onModeSelected: (mode) => themeViewModel.setMode(mode),
        onVariantSelected: (variant) => themeViewModel.setVariant(variant),
      ),
    );
  }

  void _openExport(BuildContext context) async {
    try {
      final path = await localBackupService.saveBackupToDevice();
      if (!context.mounted || path == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup salvo: $path')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível exportar os dados locais.'),
        ),
      );
    }
  }

  Future<void> _confirmSwitchMode(BuildContext context) async {
    final navigator = Navigator.of(context);

    final confirmed = await showTechReportConfirmationDialog(
      context: context,
      title: 'Trocar para modo empresa?',
      message: 'Seus RATs locais permanecem neste dispositivo.',
      confirmLabel: 'Trocar',
      cancelLabel: 'Cancelar',
    );

    if (confirmed) {
      navigator.pop();
      await onSwitchMode();
    }
  }

  void _openImport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocalDataImportScreen(
          viewModel: LocalDataImportViewModel(
            previewLocalBackup: PreviewLocalBackup(parser: localBackupParser),
            applyLocalBackup: ApplyLocalBackup(
              parser: localBackupParser,
              applyLocalDataImport: applyLocalDataImport,
            ),
            localDataImportParser: localDataImportParser,
            previewLocalDataImport: previewLocalDataImport,
            applyLocalDataImport: applyLocalDataImport,
          ),
        ),
      ),
    );
  }
}

class _ChangePinScreen extends StatefulWidget {
  const _ChangePinScreen({required this.viewModel});

  final AppSessionViewModel viewModel;

  @override
  State<_ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<_ChangePinScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Alterar PIN')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(MetricSlateSpacing.lg),
          children: [
            if (widget.viewModel.pinConfigured) ...[
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
              const SizedBox(height: MetricSlateSpacing.md),
            ],
            TextField(
              controller: _newPinController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Novo PIN (4 a 8 dígitos ou vazio para remover)',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: MetricSlateSpacing.md),
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
            if (_errorMessage != null) ...[
              const SizedBox(height: MetricSlateSpacing.md),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: MetricSlateSpacing.lg),
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
      currentPin: widget.viewModel.pinConfigured
          ? _currentPinController.text
          : null,
      newPin: _newPinController.text,
      confirmation: _confirmationController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN atualizado.')));
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage =
          widget.viewModel.errorMessage ?? 'Não foi possível alterar o PIN.';
    });
  }
}

class _ThemeSelectorSheet extends StatelessWidget {
  const _ThemeSelectorSheet({
    required this.currentMode,
    required this.currentVariant,
    required this.onModeSelected,
    required this.onVariantSelected,
  });

  final AppThemeModePreference currentMode;
  final AppThemeVariant currentVariant;
  final ValueChanged<AppThemeModePreference> onModeSelected;
  final ValueChanged<AppThemeVariant> onVariantSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: MetricSlateSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(MetricSlateSpacing.lg),
              child: Text(
                'Aparência',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),

            // ── Modo de aparência ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MetricSlateSpacing.lg,
                MetricSlateSpacing.md,
                MetricSlateSpacing.lg,
                MetricSlateSpacing.xs,
              ),
              child: Text(
                'Modo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...[
              for (final mode in AppThemeModePreference.values)
                RadioListTile<AppThemeModePreference>(
                  value: mode,
                  groupValue: currentMode,
                  onChanged: (value) {
                    if (value != null) onModeSelected(value);
                  },
                  title: Text(mode.label),
                  secondary: Icon(_modeIcon(mode)),
                ),
            ],

            const Divider(height: MetricSlateSpacing.lg),

            // ── Paleta de cores ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MetricSlateSpacing.lg,
                MetricSlateSpacing.xs,
                MetricSlateSpacing.lg,
                MetricSlateSpacing.xs,
              ),
              child: Text(
                'Cores',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...[
              for (final variant in AppThemeVariant.values)
                RadioListTile<AppThemeVariant>(
                  value: variant,
                  groupValue: currentVariant,
                  onChanged: (value) {
                    if (value != null) onVariantSelected(value);
                  },
                  title: Text(variant.displayName),
                  subtitle: Text(variant.description),
                  secondary: Icon(_variantIcon(variant)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _modeIcon(AppThemeModePreference mode) {
    return switch (mode) {
      AppThemeModePreference.system => Icons.settings_brightness_outlined,
      AppThemeModePreference.light => Icons.light_mode_outlined,
      AppThemeModePreference.dark => Icons.dark_mode_outlined,
    };
  }

  IconData _variantIcon(AppThemeVariant variant) {
    return switch (variant) {
      AppThemeVariant.cobalt => Icons.water_drop_outlined,
      AppThemeVariant.volt => Icons.flash_on_outlined,
      AppThemeVariant.burgundy => Icons.wine_bar_outlined,
    };
  }
}
