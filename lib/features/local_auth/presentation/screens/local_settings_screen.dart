import 'package:flutter/material.dart';
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
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';

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
            _SectionHeader(title: 'Dados locais'),
            const SizedBox(height: MetricSlateSpacing.sm),
            _SettingsCard(
              icon: Icons.file_upload_outlined,
              title: 'Exportar dados',
              subtitle: 'Salve um backup local dos RATs.',
              onTap: () => _openExport(context),
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            _SettingsCard(
              icon: Icons.file_download_outlined,
              title: 'Importar dados',
              subtitle: 'Restaure RATs de um backup.',
              onTap: () => _openImport(context),
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            _SectionHeader(title: 'Segurança'),
            const SizedBox(height: MetricSlateSpacing.sm),
            _SettingsCard(
              icon: Icons.pin_outlined,
              title: appSessionViewModel.pinConfigured
                  ? 'Trocar PIN'
                  : 'Criar PIN',
              subtitle: appSessionViewModel.pinConfigured
                  ? 'Altere ou remova o PIN de bloqueio.'
                  : 'Proteja o modo local com um PIN.',
              onTap: () => _openChangePin(context),
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            _SectionHeader(title: 'Aparência'),
            const SizedBox(height: MetricSlateSpacing.sm),
            _SettingsCard(
              icon: Icons.palette_outlined,
              title: 'Tema do app',
              subtitle: 'Escolha a paleta de cores do TechReport.',
              trailing: Text(
                themeViewModel.currentVariant.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onTap: () => _openThemeSelector(context),
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            _SectionHeader(title: 'Modo de operação'),
            const SizedBox(height: MetricSlateSpacing.sm),
            _SettingsCard(
              icon: Icons.cloud_outlined,
              title: 'Trocar para modo empresa',
              subtitle: 'Conecte-se ao servidor da empresa.',
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
      builder: (ctx) => _ThemeSelectorSheet(
        currentVariant: themeViewModel.currentVariant,
        onSelected: (variant) {
          themeViewModel.setVariant(variant);
          Navigator.of(ctx).pop();
        },
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trocar para modo empresa?'),
        content: const Text('Seus RATs locais permanecem neste dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Trocar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TechReportCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: MetricSlateSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: MetricSlateSpacing.sm),
            trailing!,
          ] else
            const Icon(Icons.chevron_right),
        ],
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
    required this.currentVariant,
    required this.onSelected,
  });

  final AppThemeVariant currentVariant;
  final ValueChanged<AppThemeVariant> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(MetricSlateSpacing.lg),
            child: Text(
              'Escolha o tema',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ...[
            for (final variant in AppThemeVariant.values)
              RadioListTile<AppThemeVariant>(
                value: variant,
                groupValue: currentVariant,
                onChanged: (value) {
                  if (value != null) onSelected(value);
                },
                title: Text(variant.displayName),
                subtitle: Text(variant.description),
                secondary: Icon(_variantIcon(variant)),
              ),
          ],
          const SizedBox(height: MetricSlateSpacing.md),
        ],
      ),
    );
  }

  IconData _variantIcon(AppThemeVariant variant) {
    return switch (variant) {
      AppThemeVariant.cobalt => Icons.water_drop_outlined,
      AppThemeVariant.volt => Icons.flash_on_outlined,
      AppThemeVariant.burgundy => Icons.wine_bar_outlined,
    };
  }
}
