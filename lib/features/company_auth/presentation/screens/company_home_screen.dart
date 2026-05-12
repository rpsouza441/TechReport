import 'package:flutter/material.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';

// TODO: Reavaliar como dashboard do modo empresa na Sprint 6.
class CompanyHomeScreen extends StatelessWidget {
  const CompanyHomeScreen({
    super.key,
    required this.session,
    required this.onSignOut,
  });

  final SessaoRemota session;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo empresa'),
        actions: [
          IconButton(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
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
                    'Empresa conectada',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login remoto validado e tecnico vinculado.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _StatusRow(
                    icon: Icons.business_outlined,
                    label: 'Empresa',
                    value: 'Vinculada',
                  ),
                  _StatusRow(
                    icon: Icons.badge_outlined,
                    label: 'Tecnico',
                    value: 'Vinculado',
                  ),
                  _StatusRow(
                    icon: Icons.check_circle_outline,
                    label: 'Sessao',
                    value: _formatStatus(session.status),
                  ),
                  const SizedBox(height: 24),
                  _TechnicalDetails(session: session),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onSignOut,
                    child: const Text('Sair da empresa'),
                  ),
                ],
              ),
            ),
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

class _TechnicalDetails extends StatelessWidget {
  const _TechnicalDetails({required this.session});

  final SessaoRemota session;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
      title: const Text('Detalhes tecnicos'),
      children: [
        _InfoRow(label: 'Empresa ID', value: session.empresaId),
        _InfoRow(label: 'Usuario ID', value: session.usuarioId),
        _InfoRow(label: 'Tecnico ID', value: session.tecnicoId),
        _InfoRow(label: 'Status', value: session.status.name),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
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
