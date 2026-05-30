import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/presentation/view_models/admin_empresa_view_model.dart';
import 'package:techreport/shared/presentation/widgets/metric_slate_text_field.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_section_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

class AdminEmpresaArea extends StatefulWidget {
  const AdminEmpresaArea({super.key, required this.viewModel});

  final AdminEmpresaViewModel viewModel;

  @override
  State<AdminEmpresaArea> createState() => _AdminEmpresaAreaState();
}

class _AdminEmpresaAreaState extends State<AdminEmpresaArea> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: widget.viewModel.load,
              child: _buildBody(context),
            ),
            if (widget.viewModel.isSubmitting)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Positioned(
              right: MetricSlateSpacing.lg,
              bottom: MetricSlateSpacing.lg,
              child: FloatingActionButton.extended(
                onPressed: widget.viewModel.isSubmitting
                    ? null
                    : _openInviteDialog,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Convidar'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.viewModel.isLoading &&
        widget.viewModel.tecnicos.isEmpty &&
        widget.viewModel.convites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = widget.viewModel.errorMessage;
    final pendingConvites = widget.viewModel.convites
        .where((c) => c.isPending && !c.isExpired)
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        MetricSlateSpacing.md,
        MetricSlateSpacing.md,
        MetricSlateSpacing.md,
        88,
      ),
      children: [
        if (errorMessage != null) ...[
          TechReportErrorBanner(message: errorMessage),
          const SizedBox(height: MetricSlateSpacing.sm),
        ],
        if (pendingConvites.isNotEmpty) ...[
          const TechReportSectionHeader(
            title: 'Convites pendentes',
            subtitle: 'Compartilhe o código gerado com o convidado.',
          ),
          const SizedBox(height: MetricSlateSpacing.sm),
          for (final convite in pendingConvites) ...[
            _ConviteCard(
              convite: convite,
              onCancel: widget.viewModel.isSubmitting
                  ? null
                  : () => widget.viewModel.cancelInvite(convite.id),
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
          ],
          const SizedBox(height: MetricSlateSpacing.md),
        ],
        const TechReportSectionHeader(
          title: 'Equipe',
          subtitle: 'Membros vinculados à empresa.',
        ),
        const SizedBox(height: MetricSlateSpacing.sm),
        if (widget.viewModel.tecnicos.isEmpty)
          const TechReportStateView.empty(
            title: 'Equipe vazia',
            message: 'Convide o primeiro técnico ou gerente.',
          )
        else
          for (final tecnico in widget.viewModel.tecnicos) ...[
            _TecnicoCard(
              tecnico: tecnico,
              canManage: widget.viewModel.canManageTecnico(tecnico),
              onToggleAtivo: (ativo) => widget.viewModel.setTecnicoAtivo(
                tecnico: tecnico,
                ativo: ativo,
              ),
              onToggleMustChangePassword: (value) =>
                  widget.viewModel.setMustChangePassword(
                    tecnico: tecnico,
                    mustChangePassword: value,
                  ),
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _openInviteDialog() async {
    final nomeController = TextEditingController();
    final emailController = TextEditingController();
    var papel = AdminTecnicoPapel.tecnico;

    final result = await showDialog<CreateTecnicoConviteResult?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Convidar membro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MetricSlateTextField(
                      controller: nomeController,
                      label: 'Nome',
                    ),
                    const SizedBox(height: MetricSlateSpacing.sm),
                    MetricSlateTextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      label: 'E-mail',
                    ),
                    const SizedBox(height: MetricSlateSpacing.sm),
                    DropdownButtonFormField<AdminTecnicoPapel>(
                      initialValue: papel,
                      decoration: const InputDecoration(
                        labelText: 'Papel inicial',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AdminTecnicoPapel.tecnico,
                          child: Text('Técnico'),
                        ),
                        DropdownMenuItem(
                          value: AdminTecnicoPapel.gerente,
                          child: Text('Gerente'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => papel = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final inviteResult = await widget.viewModel.inviteMember(
                      email: emailController.text.trim(),
                      nome: nomeController.text.trim(),
                      papel: papel,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(inviteResult);
                    }
                  },
                  child: const Text('Gerar convite'),
                ),
              ],
            );
          },
        );
      },
    );

    nomeController.dispose();
    emailController.dispose();

    if (!mounted || result == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Convite criado'),
          content: SelectableText(
            'Código: ${result.codigoConvite}\n\n'
            'Válido até ${_formatDateTime(result.expiresAt)}.\n\n'
            'Envie este código ao convidado. Ele deve entrar com o e-mail '
            'convidado, senha e código em "Aceitar convite".',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _ConviteCard extends StatelessWidget {
  const _ConviteCard({required this.convite, required this.onCancel});

  final AdminConviteResumo convite;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mail_outline, color: theme.colorScheme.primary),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(convite.nome, style: theme.textTheme.titleMedium),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(convite.email),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(
                  _papelLabel(convite.papel),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(
                  'Expira em ${_formatDateTime(convite.expiresAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancelar convite',
            ),
        ],
      ),
    );
  }

  String _papelLabel(AdminTecnicoPapel papel) {
    return switch (papel) {
      AdminTecnicoPapel.adminEmpresa => 'Admin empresa',
      AdminTecnicoPapel.gerente => 'Gerente',
      AdminTecnicoPapel.tecnico => 'Técnico',
    };
  }

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

class _TecnicoCard extends StatelessWidget {
  const _TecnicoCard({
    required this.tecnico,
    required this.canManage,
    required this.onToggleAtivo,
    required this.onToggleMustChangePassword,
  });

  final AdminTecnicoResumo tecnico;
  final bool canManage;
  final ValueChanged<bool> onToggleAtivo;
  final ValueChanged<bool> onToggleMustChangePassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tecnico.ativo ? Icons.badge_outlined : Icons.person_off_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tecnico.nome, style: theme.textTheme.titleMedium),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(tecnico.email, style: theme.textTheme.bodyMedium),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(
                  _papelLabel(tecnico.papel),
                  style: theme.textTheme.labelMedium,
                ),
                if (tecnico.mustChangePassword) ...[
                  const SizedBox(height: MetricSlateSpacing.xxs),
                  Text(
                    'Deve trocar senha no próximo acesso',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TechReportStatusChip(
                label: tecnico.ativo ? 'Ativo' : 'Inativo',
                tone: tecnico.ativo
                    ? TechReportStatusTone.success
                    : TechReportStatusTone.neutral,
              ),
              if (canManage) ...[
                const SizedBox(height: MetricSlateSpacing.xxs),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'activate':
                        onToggleAtivo(true);
                      case 'deactivate':
                        onToggleAtivo(false);
                      case 'must_change_on':
                        onToggleMustChangePassword(true);
                      case 'must_change_off':
                        onToggleMustChangePassword(false);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!tecnico.ativo)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Text('Ativar'),
                      ),
                    if (tecnico.ativo)
                      const PopupMenuItem(
                        value: 'deactivate',
                        child: Text('Desativar'),
                      ),
                    if (!tecnico.mustChangePassword)
                      const PopupMenuItem(
                        value: 'must_change_on',
                        child: Text('Exigir troca de senha'),
                      ),
                    if (tecnico.mustChangePassword)
                      const PopupMenuItem(
                        value: 'must_change_off',
                        child: Text('Remover exigência de senha'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _papelLabel(AdminTecnicoPapel papel) {
    return switch (papel) {
      AdminTecnicoPapel.adminEmpresa => 'Admin empresa',
      AdminTecnicoPapel.gerente => 'Gerente',
      AdminTecnicoPapel.tecnico => 'Técnico',
    };
  }
}
