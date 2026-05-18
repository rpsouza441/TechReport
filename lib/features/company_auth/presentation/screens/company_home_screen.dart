import 'package:flutter/material.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';

class CompanyHomeScreen extends StatelessWidget {
  const CompanyHomeScreen({super.key, required this.session});

  final SessaoRemota session;

  @override
  Widget build(BuildContext context) {
    final isAppAdminOnly = session.isAppAdmin && !session.hasCompanyContext;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
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
              const SizedBox(height: 32),
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
                const _StatusRow(
                  icon: Icons.badge_outlined,
                  label: 'Tecnico',
                  value: 'Vinculado',
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
            ],
          ),
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
          Text(value, textAlign: TextAlign.end),
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
