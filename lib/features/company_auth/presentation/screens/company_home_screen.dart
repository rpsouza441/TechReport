import 'package:flutter/material.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/usecases/change_company_password.dart';
import 'package:techreport/features/company_auth/presentation/view_models/company_account_view_model.dart';

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
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.verified_user_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isAppAdminOnly ? 'Admin conectado' : 'Empresa conectada',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isAppAdminOnly
                    ? 'Login remoto validado como admin global.'
                    : 'Login remoto validado e técnico vinculado.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (session.mustChangePassword) ...[
                const _WarningBox(
                  message:
                      'Sua senha precisa ser atualizada para manter a conta segura.',
                ),
                const SizedBox(height: 16),
              ],
              _StatusRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: session.email.isEmpty ? 'Não informado' : session.email,
              ),
              _StatusRow(
                icon: Icons.person_outline,
                label: 'Nome',
                value: nome == null || nome.isEmpty ? 'Não informado' : nome,
              ),
              if (session.isAppAdmin)
                const _StatusRow(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin global',
                  value: 'Ativo',
                ),
              if (session.hasCompanyContext) ...[
                const _StatusRow(
                  icon: Icons.business_outlined,
                  label: 'Empresa',
                  value: 'Vinculada',
                ),
                _StatusRow(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Papel',
                  value: _formatPapelEmpresa(session.papelEmpresa),
                ),
              ],
              _StatusRow(
                icon: Icons.check_circle_outline,
                label: 'Sessão',
                value: _formatStatus(session.status),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _openChangePasswordScreen(context),
                icon: const Icon(Icons.lock_reset_outlined),
                label: const Text('Trocar senha'),
              ),
            ],
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
        return Scaffold(
          appBar: AppBar(title: const Text('Trocar senha')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Defina uma nova senha',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Depois da troca, entre novamente com a senha nova.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.viewModel.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.viewModel.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nova senha',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar senha',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: widget.viewModel.isChangingPassword
                            ? null
                            : _submit,
                        child: widget.viewModel.isChangingPassword
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Salvar senha'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: widget.viewModel.isChangingPassword
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

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
