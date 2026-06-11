import 'package:flutter/material.dart';
import 'package:techreport/app/di/app_scope.dart';
import 'package:techreport/app/theme/app_theme_variant.dart';
import 'package:techreport/app/theme/app_theme_view_model.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';
import 'package:techreport/features/company_auth/domain/usecases/change_company_password.dart';
import 'package:techreport/features/company_auth/domain/usecases/update_own_display_name.dart';
import 'package:techreport/features/company_auth/presentation/view_models/company_account_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_info_row.dart';
import 'package:techreport/features/company_auth/presentation/screens/company_edit_profile_screen.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({
    super.key,
    required this.sessionNotifier,
    required this.scope,
    required this.changePassword,
    required this.onPasswordChanged,
    required this.themeViewModel,
  });

  final ValueNotifier<SessaoRemota?> sessionNotifier;
  final AppScope scope;
  final ChangeCompanyPassword changePassword;
  final Future<void> Function() onPasswordChanged;
  final AppThemeViewModel themeViewModel;

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  late final CompanyAccountViewModel _accountViewModel;

  @override
  void initState() {
    super.initState();
    _accountViewModel = CompanyAccountViewModel(
      changePassword: widget.changePassword,
      updateOwnDisplayName: UpdateOwnDisplayName(
        authRepository: widget.scope.authRepository,
      ),
      remoteSessionRepository: widget.scope.remoteSessionRepository,
      sessionNotifier: widget.sessionNotifier,
    );
    widget.sessionNotifier.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.sessionNotifier.removeListener(_onSessionChanged);
    _accountViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.themeViewModel,
        widget.sessionNotifier,
      ]),
      builder: (context, _) {
        final session = widget.sessionNotifier.value;
        if (session == null) {
          return const SizedBox.shrink();
        }
        return _CompanyHomeScreenBody(
          session: session,
          sessionNotifier: widget.sessionNotifier,
          remoteSessionRepository: widget.scope.remoteSessionRepository,
          themeViewModel: widget.themeViewModel,
          onChangePassword: _openChangePasswordScreen,
        );
      },
    );
  }

  void _onSessionChanged() {
    setState(() {});
  }

  Future<void> _openChangePasswordScreen() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CompanyChangePasswordScreen(viewModel: _accountViewModel),
      ),
    );

    if (!context.mounted || changed != true) {
      return;
    }

    await widget.onPasswordChanged();
  }
}

class _CompanyHomeScreenBody extends StatefulWidget {
  const _CompanyHomeScreenBody({
    required this.session,
    required this.sessionNotifier,
    required this.remoteSessionRepository,
    required this.themeViewModel,
    required this.onChangePassword,
  });

  final SessaoRemota session;
  final ValueNotifier<SessaoRemota?> sessionNotifier;
  final dynamic remoteSessionRepository;
  final AppThemeViewModel themeViewModel;
  final VoidCallback onChangePassword;

  @override
  State<_CompanyHomeScreenBody> createState() => _CompanyHomeScreenBodyState();
}

class _CompanyHomeScreenBodyState extends State<_CompanyHomeScreenBody> {
  @override
  void initState() {
    super.initState();
    widget.sessionNotifier.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.sessionNotifier.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionNotifier.value ?? widget.session;
    final nome = session.nome?.trim();

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MetricSlateSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Seção: Identidade ────────────────────────────────────────
              _buildIdentitySection(context, nome),
              const SizedBox(height: MetricSlateSpacing.lg),

              // ── Seção: Dados cadastrais ──────────────────────────────────
              _buildCadastralSection(context),
              const SizedBox(height: MetricSlateSpacing.lg),

              // ── Seção: Segurança ─────────────────────────────────────────
              _buildSecuritySection(context),
              const SizedBox(height: MetricSlateSpacing.lg),

              // ── Seção: Preferências ─────────────────────────────────────
              _buildPreferencesSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentitySection(BuildContext context, String? nome) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = widget.sessionNotifier.value ?? widget.session;
    final initials = _initials(nome ?? session.email);
    final displayName = nome?.isNotEmpty == true ? nome! : session.email;

    return TechReportCard(
      child: Column(
        children: [
          // ── Avatar centralizado ───────────────────────────────
          CircleAvatar(
            radius: 36,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initials,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: MetricSlateSpacing.md),

          // ── Nome ─────────────────────────────────────────────
          Text(
            displayName,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),

          // ── Badge Admin global ───────────────────────────────
          if (session.isAppAdmin)
            Padding(
              padding: const EdgeInsets.only(top: MetricSlateSpacing.xs),
              child: Chip(
                avatar: Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 16,
                  color: scheme.onSecondaryContainer,
                ),
                label: const Text('Admin global'),
                backgroundColor: scheme.secondaryContainer,
                labelStyle: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),

          // ── Botão Editar nome ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: MetricSlateSpacing.sm),
            child: TextButton.icon(
              onPressed: () => _openEditProfile(context, nome),
              icon: Icon(Icons.edit_outlined, size: 18, color: scheme.primary),
              label: Text(
                'Editar nome',
                style: TextStyle(color: scheme.primary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: MetricSlateSpacing.md,
                  vertical: MetricSlateSpacing.sm,
                ),
                minimumSize: const Size(44, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCadastralSection(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.sessionNotifier.value ?? widget.session;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: MetricSlateSpacing.xxs,
            bottom: MetricSlateSpacing.xs,
          ),
          child: Text(
            'Dados cadastrais',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        TechReportCard(
          child: Column(
            children: [
              TechReportInfoRow(
                icon: Icons.mail_outlined,
                label: 'E-mail',
                value: session.email.isEmpty ? 'Não informado' : session.email,
              ),
              if (session.hasCompanyContext) ...[
                const Divider(height: 1),
                TechReportInfoRow(
                  icon: Icons.business_outlined,
                  label: 'Empresa',
                  value: 'Vinculada',
                ),
                const Divider(height: 1),
                TechReportInfoRow(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Papel',
                  value: _formatPapelEmpresa(session.papelEmpresa),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.sessionNotifier.value ?? widget.session;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: MetricSlateSpacing.xxs,
            bottom: MetricSlateSpacing.xs,
          ),
          child: Text(
            'Segurança',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        TechReportCard(
          child: Column(
            children: [
              TechReportInfoRow(
                icon: Icons.check_circle_outline,
                label: 'Sessão',
                value: _formatStatus(session.status),
              ),
              if (session.mustChangePassword) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(MetricSlateSpacing.md),
                  child: TechReportCard(
                    tone: TechReportCardTone.warning,
                    padding: EdgeInsets.zero,
                    child: Row(
                      children: [
                        const SizedBox(width: MetricSlateSpacing.sm),
                        const Icon(Icons.warning_amber_outlined),
                        const SizedBox(width: MetricSlateSpacing.sm),
                        Expanded(
                          child: Text(
                            'Sua senha precisa ser atualizada.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: MetricSlateSpacing.md,
                  vertical: MetricSlateSpacing.xs,
                ),
                leading: Icon(
                  Icons.lock_reset_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Trocar senha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onChangePassword,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: MetricSlateSpacing.xxs,
            bottom: MetricSlateSpacing.xs,
          ),
          child: Text(
            'Preferências',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        TechReportCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: MetricSlateSpacing.md,
              vertical: MetricSlateSpacing.xs,
            ),
            leading: Icon(
              Icons.palette_outlined,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Tema'),
            subtitle: Text(widget.themeViewModel.currentVariant.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openThemeSelector(context),
          ),
        ),
      ],
    );
  }

  void _openThemeSelector(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CompanyThemeScreen(
          currentVariant: widget.themeViewModel.currentVariant,
          onSelected: (variant) {
            widget.themeViewModel.setVariant(variant);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _openEditProfile(
    BuildContext context,
    String? currentName,
  ) async {
    final newName = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CompanyEditProfileScreen(
          initialName: currentName,
          onSave: (name) async {
            // Placeholder: integrar com session update quando API existir
            // Por ora, apenas retorna true para permitir fluxo de UI
            await Future.delayed(const Duration(milliseconds: 300));
            return true;
          },
        ),
      ),
    );

    if (!context.mounted || newName == null) return;

    // Atualiza sessão em memória + persiste localmente.
    final current = widget.sessionNotifier.value;
    if (current != null) {
      widget.sessionNotifier.value = current.copyWith(nome: newName);
      await widget.remoteSessionRepository.updateSession(
        current.copyWith(nome: newName),
      );
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _CompanyThemeScreen extends StatelessWidget {
  const _CompanyThemeScreen({
    required this.currentVariant,
    required this.onSelected,
  });

  final AppThemeVariant currentVariant;
  final ValueChanged<AppThemeVariant> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar tema')),
      body: ListView(
        children: [
          for (final variant in AppThemeVariant.values)
            RadioListTile<AppThemeVariant>(
              value: variant,
              groupValue: currentVariant,
              onChanged: (v) {
                if (v != null) onSelected(v);
              },
              title: Text(variant.displayName),
              subtitle: Text(variant.description),
              secondary: Icon(_variantIcon(variant)),
            ),
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

class CompanyChangePasswordScreen extends StatefulWidget {
  const CompanyChangePasswordScreen({super.key, required this.viewModel});

  final CompanyAccountViewModel viewModel;

  @override
  State<CompanyChangePasswordScreen> createState() =>
      _CompanyChangePasswordScreenState();
}

class _CompanyChangePasswordScreenState
    extends State<CompanyChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    // Não dispõe widget.viewModel: ele pertence ao CompanyHomeScreen, que o
    // reutiliza após esta tela fechar. O dono cuida do dispose.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final isChanging = widget.viewModel.isChangingPassword;

        return Scaffold(
          appBar: AppBar(title: const Text('Trocar senha')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TechReportCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TechReportFormHeader(
                          icon: Icons.lock_reset_outlined,
                          title: 'Nova senha',
                          subtitle:
                              'Depois da troca, entre novamente com a senha nova.',
                        ),
                        if (widget.viewModel.errorMessage != null) ...[
                          const SizedBox(height: MetricSlateSpacing.md),
                          TechReportErrorBanner(
                            message: widget.viewModel.errorMessage!,
                          ),
                        ],
                        const SizedBox(height: MetricSlateSpacing.lg),
                        TextField(
                          controller: _newPasswordController,
                          enabled: !isChanging,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'Nova senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: isChanging
                                  ? null
                                  : () => setState(
                                      () => _obscureNewPassword =
                                          !_obscureNewPassword,
                                    ),
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: MetricSlateSpacing.md),
                        TextField(
                          controller: _confirmPasswordController,
                          enabled: !isChanging,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirmar senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: isChanging
                                  ? null
                                  : () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: MetricSlateSpacing.lg),
                        FilledButton.icon(
                          onPressed: isChanging ? null : _submit,
                          icon: isChanging
                              ? SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.save_outlined, size: 20),
                          label: Text(
                            isChanging ? 'Salvando...' : 'Salvar senha',
                          ),
                        ),
                        const SizedBox(height: MetricSlateSpacing.sm),
                        OutlinedButton(
                          onPressed: isChanging
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (widget.viewModel.isChangingPassword) {
      return;
    }

    await widget.viewModel.changePassword(
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted || widget.viewModel.errorMessage != null) {
      return;
    }

    Navigator.of(context).pop(true);
  }
}

String _formatStatus(SessaoRemotaStatus status) {
  switch (status) {
    case SessaoRemotaStatus.valid:
      return 'Válida';
    case SessaoRemotaStatus.offlineAllowed:
      return 'Offline permitido';
    case SessaoRemotaStatus.expired:
      return 'Expirada';
    case SessaoRemotaStatus.invalid:
      return 'Inválida';
  }
}

String _formatPapelEmpresa(SessaoRemotaPapelEmpresa? papel) {
  switch (papel) {
    case SessaoRemotaPapelEmpresa.adminEmpresa:
      return 'Admin empresa';
    case SessaoRemotaPapelEmpresa.gerente:
      return 'Gerente';
    case SessaoRemotaPapelEmpresa.tecnico:
      return 'Técnico';
    case null:
      return '-';
  }
}
