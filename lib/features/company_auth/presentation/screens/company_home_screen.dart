import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/usecases/change_company_password.dart';
import 'package:techreport/features/company_auth/presentation/view_models/company_account_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_info_row.dart';

class CompanyHomeScreen extends StatelessWidget {
  const CompanyHomeScreen({
    super.key,
    required this.session,
    required this.changePassword,
    required this.onPasswordChanged,
  });

  final SessaoRemota session;
  final ChangeCompanyPassword changePassword;
  final Future<void> Function() onPasswordChanged;

  @override
  Widget build(BuildContext context) {
    final isAppAdminOnly = session.isAppAdmin && !session.hasCompanyContext;
    final nome = session.nome?.trim();

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MetricSlateSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: TechReportCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TechReportFormHeader(
                  icon: Icons.verified_user_outlined,
                  title: isAppAdminOnly ? 'Admin conectado' : 'Meu perfil',
                  subtitle: isAppAdminOnly
                      ? 'Login remoto validado como admin global.'
                      : 'Login remoto validado e técnico vinculado.',
                ),
                if (session.mustChangePassword) ...[
                  const SizedBox(height: MetricSlateSpacing.md),
                  TechReportCard(
                    tone: TechReportCardTone.warning,
                    padding: const EdgeInsets.all(MetricSlateSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined),
                        const SizedBox(width: MetricSlateSpacing.sm),
                        Expanded(
                          child: Text(
                            'Sua senha precisa ser atualizada para manter a conta segura.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: MetricSlateSpacing.lg),
                TechReportInfoRow(
                  icon: Icons.email_outlined,
                  label: 'E-mail',
                  value:
                      session.email.isEmpty ? 'Não informado' : session.email,
                ),
                TechReportInfoRow(
                  icon: Icons.person_outline,
                  label: 'Nome',
                  value: nome == null || nome.isEmpty ? 'Não informado' : nome,
                ),
                if (session.isAppAdmin)
                  const TechReportInfoRow(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin global',
                    value: 'Ativo',
                  ),
                if (session.hasCompanyContext) ...[
                  const TechReportInfoRow(
                    icon: Icons.business_outlined,
                    label: 'Empresa',
                    value: 'Vinculada',
                  ),
                  TechReportInfoRow(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Papel',
                    value: _formatPapelEmpresa(session.papelEmpresa),
                  ),
                ],
                TechReportInfoRow(
                  icon: Icons.check_circle_outline,
                  label: 'Sessão',
                  value: _formatStatus(session.status),
                ),
                const SizedBox(height: MetricSlateSpacing.lg),
                FilledButton.icon(
                  onPressed: () => _openChangePasswordScreen(context),
                  icon: const Icon(Icons.lock_reset_outlined, size: 20),
                  label: const Text('Trocar senha'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChangePasswordScreen(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyChangePasswordScreen(
          viewModel: CompanyAccountViewModel(changePassword: changePassword),
        ),
      ),
    );

    if (!context.mounted || changed != true) {
      return;
    }

    await onPasswordChanged();
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
    widget.viewModel.dispose();
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
