import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/presentation/view_models/admin_empresa_view_model.dart';
import 'package:techreport/features/company_admin/presentation/screens/company_invite_member_screen.dart';
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
  final _nomeController = TextEditingController();
  bool _isEditingNome = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
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
            if (widget.viewModel.isSubmitting || widget.viewModel.isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Positioned(
              right: MetricSlateSpacing.lg,
              bottom: MetricSlateSpacing.lg,
              child: widget.viewModel.canInviteMembers
                  ? FloatingActionButton.extended(
                      onPressed: widget.viewModel.isSubmitting
                          ? null
                          : _openInviteScreen,
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Convidar'),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openInviteScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyInviteMemberScreen(viewModel: widget.viewModel),
      ),
    );

    if (!mounted || created != true) {
      return;
    }

    await widget.viewModel.load();
  }

  Future<void> _confirmDeleteConvite(String conviteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir convite pendente?'),
          content: const Text(
            'O convite sera removido e o e-mail ficara livre para um novo convite.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.viewModel.cancelInvite(conviteId);
    }
  }

  void _cancelEditNome() {
    setState(() {
      _isEditingNome = false;
    });
  }

  Widget _buildEmpresaHeader() {
    final empresa = widget.viewModel.empresa;
    final theme = Theme.of(context);
    final nome = empresa?.nome ?? '';

    return TechReportCard(
      child: Row(
        children: [
          Icon(Icons.business_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: _isEditingNome
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            hintText: 'Nome da empresa',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(width: MetricSlateSpacing.xxs),
                      IconButton(
                        onPressed: widget.viewModel.isSubmitting
                            ? null
                            : _saveNome,
                        icon: const Icon(Icons.check_outlined),
                        tooltip: 'Salvar',
                      ),
                      IconButton(
                        onPressed: widget.viewModel.isSubmitting
                            ? null
                            : _cancelEditNome,
                        icon: const Icon(Icons.close_outlined),
                        tooltip: 'Cancelar',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(nome, style: theme.textTheme.titleMedium),
                      ),
                      IconButton(
                        onPressed: _startEditNome,
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar nome',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _startEditNome() {
    _nomeController.text = widget.viewModel.empresa?.nome ?? '';
    setState(() {
      _isEditingNome = true;
    });
  }

  Future<void> _saveNome() async {
    final novoNome = _nomeController.text.trim();
    if (novoNome.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome da empresa não pode ser vazio.')),
        );
      }
      return;
    }

    final sucesso = await widget.viewModel.updateNome(novoNome);
    if (sucesso && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nome atualizado.')));
      setState(() {
        _isEditingNome = false;
      });
    }
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
        if (widget.viewModel.canEditNome) _buildEmpresaHeader(),
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
                  : () => _confirmDeleteConvite(convite.id),
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
          TechReportStateView.empty(
            title: 'Equipe vazia',
            message: widget.viewModel.currentPapel == AdminTecnicoPapel.gerente
                ? 'Nenhum técnico vinculado à empresa.'
                : 'Convide o primeiro técnico ou gerente.',
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

  // Legacy dialog kept only as rollback reference while Sprint 8.5 migrates to
  // the dedicated invite screen.
  // ignore: unused_element
  Future<void> _openInviteDialog() async {
    final nomeController = TextEditingController();
    final emailController = TextEditingController();
    var papel = AdminTecnicoPapel.tecnico;
    String? dialogError;

    final result = await showDialog<CreateTecnicoConviteResult?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Convidar membro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'O convite não cria usuário no Supabase Auth. '
                      'Primeiro gere o código; depois o convidado entra com '
                      'e-mail, senha e código em "Aceitar convite".',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: MetricSlateSpacing.sm),
                    if (dialogError != null) ...[
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: MetricSlateSpacing.sm),
                    ],
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
                      key: ValueKey(papel),
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
                          setDialogState(() => papel = value);
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
                    final nome = nomeController.text.trim();
                    final email = emailController.text.trim();

                    if (nome.isEmpty) {
                      setDialogState(
                        () => dialogError = 'Informe o nome do convidado.',
                      );
                      return;
                    }

                    if (email.isEmpty || !email.contains('@')) {
                      setDialogState(
                        () => dialogError = 'Informe um e-mail válido.',
                      );
                      return;
                    }

                    setDialogState(() => dialogError = null);

                    try {
                      final inviteResult = await widget.viewModel.createConvite(
                        email: email,
                        nome: nome,
                        papel: papel,
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(inviteResult);
                      }
                    } catch (error) {
                      if (!dialogContext.mounted) {
                        return;
                      }
                      setDialogState(
                        () => dialogError = _inviteErrorMessage(error),
                      );
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

    final invitedEmail = emailController.text.trim();
    nomeController.dispose();
    emailController.dispose();

    if (!mounted || result == null) {
      return;
    }

    await widget.viewModel.load();

    if (!mounted) {
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
            '1. Crie o usuário $invitedEmail '
            'no Supabase Auth (Authentication) com o mesmo e-mail, se ainda não existir.\n'
            '2. Envie o código ao convidado.\n'
            '3. No app: login → "Aceitar convite da empresa".\n\n'
            'Até aceitar o convite, não haverá linha em public.tecnicos — '
            'apenas em public.tecnico_convites.',
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

  String _inviteErrorMessage(Object error) {
    final message = error.toString();
    const prefix = 'PostgrestException(message: ';
    if (message.contains(prefix)) {
      final start = message.indexOf(prefix) + prefix.length;
      final end = message.indexOf(',', start);
      if (end > start) {
        return message.substring(start, end);
      }
    }

    if (message.contains('digest(') || message.contains('function digest')) {
      return 'Extensão pgcrypto indisponível na RPC. '
          'Execute a migration 0010_fix_tecnico_convites_digest.sql no Supabase.';
    }

    if (message.contains('Could not find the function')) {
      return 'RPC create_tecnico_convite não encontrada. '
          'Aplique a migration 0009_tecnico_convites_equipe.sql no Supabase.';
    }

    if (message.contains('tecnico_convites')) {
      return 'Tabela tecnico_convites não encontrada. '
          'Aplique a migration 0009 no Supabase.';
    }

    return widget.viewModel.errorMessage ?? 'Não foi possível gerar o convite.';
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
          _TecnicoActions(
            ativo: tecnico.ativo,
            canManage: canManage,
            mustChangePassword: tecnico.mustChangePassword,
            onToggleAtivo: onToggleAtivo,
            onToggleMustChangePassword: onToggleMustChangePassword,
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

class _TecnicoActions extends StatelessWidget {
  const _TecnicoActions({
    required this.ativo,
    required this.canManage,
    required this.mustChangePassword,
    required this.onToggleAtivo,
    required this.onToggleMustChangePassword,
  });

  final bool ativo;
  final bool canManage;
  final bool mustChangePassword;
  final ValueChanged<bool> onToggleAtivo;
  final ValueChanged<bool> onToggleMustChangePassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 112,
          child: Align(
            alignment: Alignment.centerRight,
            child: TechReportStatusChip(
              label: ativo ? 'Ativo' : 'Inativo',
              tone: ativo
                  ? TechReportStatusTone.success
                  : TechReportStatusTone.neutral,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          height: 40,
          child: canManage
              ? PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
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
                    if (!ativo)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Text('Ativar'),
                      ),
                    if (ativo)
                      const PopupMenuItem(
                        value: 'deactivate',
                        child: Text('Desativar'),
                      ),
                    if (!mustChangePassword)
                      const PopupMenuItem(
                        value: 'must_change_on',
                        child: Text('Exigir troca de senha'),
                      ),
                    if (mustChangePassword)
                      const PopupMenuItem(
                        value: 'must_change_off',
                        child: Text('Remover exigência de senha'),
                      ),
                  ],
                )
              : null,
        ),
      ],
    );
  }
}
