import 'package:flutter/material.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/presentation/view_models/company_account_view_model.dart';

class CompanyHomeScreen extends StatelessWidget {
  const CompanyHomeScreen({
    super.key,
    required this.session,
    required this.viewModel,
  });

  final SessaoRemota session;
  final CompanyAccountViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isAppAdminOnly = session.isAppAdmin && !session.hasCompanyContext;
    final nome = session.nome?.trim();

    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
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
                        : 'Login remoto validado e tecnico vinculado.',
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
                    value: session.email.isEmpty
                        ? 'Nao informado'
                        : session.email,
                  ),
                  _StatusRow(
                    icon: Icons.person_outline,
                    label: 'Nome',
                    value: nome == null || nome.isEmpty
                        ? 'Nao informado'
                        : nome,
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
                    label: 'Sessao',
                    value: _formatStatus(session.status),
                  ),
                  const SizedBox(height: 24),
                  if (viewModel.errorMessage != null) ...[
                    _MessageText(
                      message: viewModel.errorMessage!,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (viewModel.successMessage != null) ...[
                    _MessageText(
                      message: viewModel.successMessage!,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: viewModel.isChangingPassword
                        ? null
                        : () => _showChangePasswordDialog(context),
                    icon: viewModel.isChangingPassword
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_reset_outlined),
                    label: const Text('Trocar senha'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Trocar senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                await viewModel.changePassword(
                  newPassword: newPasswordController.text,
                  confirmPassword: confirmPasswordController.text,
                );
                newPasswordController.clear();
                confirmPasswordController.clear();
                if (dialogContext.mounted && viewModel.errorMessage == null) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    newPasswordController.dispose();
    confirmPasswordController.dispose();
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

class _MessageText extends StatelessWidget {
  const _MessageText({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: color),
      textAlign: TextAlign.center,
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
      return 'Valida';
    case SessaoRemotaStatus.offlineAllowed:
      return 'Offline permitido';
    case SessaoRemotaStatus.expired:
      return 'Expirada';
    case SessaoRemotaStatus.invalid:
      return 'Invalida';
  }
}

String _formatPapelEmpresa(SessaoRemotaPapelEmpresa? papel) {
  switch (papel) {
    case SessaoRemotaPapelEmpresa.adminEmpresa:
      return 'Admin empresa';
    case SessaoRemotaPapelEmpresa.gerente:
      return 'Gerente';
    case SessaoRemotaPapelEmpresa.tecnico:
      return 'Tecnico';
    case null:
      return '-';
  }
}
