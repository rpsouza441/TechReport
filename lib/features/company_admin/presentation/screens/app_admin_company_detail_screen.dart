import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_admin_empresa.dart';
import 'package:techreport/features/company_admin/presentation/screens/app_admin_company_form_screen.dart';
import 'package:techreport/features/company_admin/presentation/view_models/app_admin_company_detail_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_section_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

class AppAdminCompanyDetailScreen extends StatefulWidget {
  const AppAdminCompanyDetailScreen({
    super.key,
    required this.viewModel,
    required this.updateAdminEmpresa,
  });

  final AppAdminCompanyDetailViewModel viewModel;
  final UpdateAdminEmpresa updateAdminEmpresa;

  @override
  State<AppAdminCompanyDetailScreen> createState() =>
      _AppAdminCompanyDetailScreenState();
}

class _AppAdminCompanyDetailScreenState
    extends State<AppAdminCompanyDetailScreen> {
  final _nomeController = TextEditingController();
  bool _isEditingNome = false;
  bool _isSavingNome = false;
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
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.of(context).pop(widget.viewModel.empresa);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.viewModel.empresa.nome),
              actions: [
                if (widget.viewModel.isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(right: MetricSlateSpacing.md),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            body: _buildBody(context),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: widget.viewModel.isSubmitting
                  ? null
                  : _openInviteScreen,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Convidar admin'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.viewModel.isLoading &&
        widget.viewModel.admins.isEmpty &&
        widget.viewModel.convites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = widget.viewModel.errorMessage;

    return RefreshIndicator(
      onRefresh: widget.viewModel.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          MetricSlateSpacing.md,
          MetricSlateSpacing.md,
          MetricSlateSpacing.md,
          88,
        ),
        children: [
          _buildHeader(),
          if (errorMessage != null) ...[
            const SizedBox(height: MetricSlateSpacing.sm),
            TechReportErrorBanner(message: errorMessage),
          ],
          const SizedBox(height: MetricSlateSpacing.md),
          _buildConvitesSection(),
          const SizedBox(height: MetricSlateSpacing.lg),
          _buildAdminsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final empresa = widget.viewModel.empresa;
    final theme = Theme.of(context);

    return TechReportCard(
      child: Row(
        children: [
          Icon(
            empresa.ativo
                ? Icons.business_outlined
                : Icons.business_center_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditingNome)
                  Row(
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
                        onPressed: _isSavingNome ? null : _saveNome,
                        icon: _isSavingNome
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_outlined),
                        tooltip: 'Salvar',
                      ),
                      IconButton(
                        onPressed: _isSavingNome ? null : _cancelEditNome,
                        icon: const Icon(Icons.close_outlined),
                        tooltip: 'Cancelar',
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              empresa.nome,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: MetricSlateSpacing.xxs),
                            Text(
                              empresa.ativo
                                  ? 'Empresa ativa'
                                  : 'Empresa inativa',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _startEditNome,
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar nome',
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (!_isEditingNome) ...[
            const SizedBox(width: MetricSlateSpacing.sm),
            ActionChip(
              label: Text(empresa.ativo ? 'Ativa' : 'Inativa'),
              avatar: Icon(
                empresa.ativo ? Icons.check_circle : Icons.cancel_outlined,
                size: 16,
                color: empresa.ativo
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              onPressed: widget.viewModel.isSubmitting
                  ? null
                  : () =>
                        widget.viewModel.setEmpresaAtiva(ativo: !empresa.ativo),
            ),
          ],
        ],
      ),
    );
  }

  void _startEditNome() {
    _nomeController.text = widget.viewModel.empresa.nome;
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

    setState(() {
      _isSavingNome = true;
    });

    try {
      await widget.updateAdminEmpresa(
        empresaId: widget.viewModel.empresa.id,
        nome: novoNome,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nome atualizado.')));
        setState(() {
          _isEditingNome = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar nome: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNome = false;
        });
      }
    }
  }

  void _cancelEditNome() {
    setState(() {
      _isEditingNome = false;
    });
  }

  Widget _buildAdminsSection() {
    final admins = widget.viewModel.admins;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TechReportSectionHeader(
          title: 'Admins da empresa',
          subtitle: 'Administradores vinculados à empresa.',
        ),
        if (admins.isEmpty)
          const TechReportStateView.empty(
            title: 'Sem admins',
            message: 'Convide o primeiro admin para esta empresa.',
          )
        else
          for (final admin in admins) ...[
            _AdminCard(
              admin: admin,
              isSubmitting: widget.viewModel.isSubmitting,
              onToggleAtivo: (ativo) =>
                  widget.viewModel.setAdminAtivo(admin: admin, ativo: ativo),
              onToggleMustChangePassword: (value) =>
                  widget.viewModel.setMustChangePassword(
                    admin: admin,
                    mustChangePassword: value,
                  ),
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
          ],
      ],
    );
  }

  Widget _buildConvitesSection() {
    final convites = widget.viewModel.convites;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TechReportSectionHeader(
          title: 'Convites pendentes',
          subtitle: 'Aguarde o convidado aceitar ou cancele o convite.',
        ),
        if (convites.isEmpty)
          const TechReportStateView.empty(
            title: 'Sem convites pendentes',
            message: 'Use o botão Convidar admin para gerar um novo convite.',
          )
        else
          for (final convite in convites) ...[
            _ConviteCard(
              convite: convite,
              isSubmitting: widget.viewModel.isSubmitting,
              onCancel: () => widget.viewModel.cancelConvite(convite.id),
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _openInviteScreen() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppAdminInviteCompanyAdminScreen(
          viewModel: null,
          empresa: widget.viewModel.empresa,
          inviteCallback: (nome, email) =>
              widget.viewModel.inviteAdmin(nome: nome, email: email),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.admin,
    required this.isSubmitting,
    required this.onToggleAtivo,
    required this.onToggleMustChangePassword,
  });

  final AdminTecnicoResumo admin;
  final bool isSubmitting;
  final ValueChanged<bool> onToggleAtivo;
  final ValueChanged<bool> onToggleMustChangePassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_circle_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin.nome, style: theme.textTheme.titleSmall),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(admin.email, style: theme.textTheme.bodySmall),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Wrap(
                  spacing: MetricSlateSpacing.xxs,
                  runSpacing: MetricSlateSpacing.xxs,
                  children: [
                    ActionChip(
                      label: Text(admin.ativo ? 'Ativo' : 'Inativo'),
                      avatar: Icon(
                        admin.ativo
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        size: 16,
                        color: admin.ativo
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () => onToggleAtivo(!admin.ativo),
                    ),
                    ActionChip(
                      label: const Text('Trocar senha'),
                      avatar: Icon(
                        Icons.key_outlined,
                        size: 16,
                        color: admin.mustChangePassword
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.outline,
                      ),
                      backgroundColor: admin.mustChangePassword
                          ? theme.colorScheme.errorContainer
                          : null,
                      onPressed: isSubmitting
                          ? null
                          : () => onToggleMustChangePassword(
                              !admin.mustChangePassword,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConviteCard extends StatefulWidget {
  const _ConviteCard({
    required this.convite,
    required this.isSubmitting,
    required this.onCancel,
  });

  final AdminConviteResumo convite;
  final bool isSubmitting;
  final VoidCallback onCancel;

  @override
  State<_ConviteCard> createState() => _ConviteCardState();
}

class _ConviteCardState extends State<_ConviteCard> {
  void _share() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _ConviteShareSheet(convite: widget.convite),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.convite.nome, style: theme.textTheme.titleSmall),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(widget.convite.email, style: theme.textTheme.bodySmall),
                const SizedBox(height: MetricSlateSpacing.xxs),
                TechReportStatusChip(
                  label: widget.convite.isExpired ? 'Expirado' : 'Pendente',
                  tone: widget.convite.isExpired
                      ? TechReportStatusTone.error
                      : TechReportStatusTone.info,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _share,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartilhar convite',
          ),
          if (!widget.convite.isExpired)
            IconButton(
              onPressed: widget.isSubmitting ? null : widget.onCancel,
              icon: widget.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close_outlined),
              tooltip: 'Cancelar convite',
            ),
        ],
      ),
    );
  }
}

class _ConviteShareSheet extends StatelessWidget {
  const _ConviteShareSheet({required this.convite});

  final AdminConviteResumo convite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: MetricSlateSpacing.lg,
        right: MetricSlateSpacing.lg,
        top: MetricSlateSpacing.lg,
        bottom:
            MetricSlateSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, color: theme.colorScheme.primary),
              const SizedBox(width: MetricSlateSpacing.sm),
              Text('Compartilhar convite', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: MetricSlateSpacing.md),
          Text('Nome: ${convite.nome}', style: theme.textTheme.bodyMedium),
          Text('E-mail: ${convite.email}', style: theme.textTheme.bodyMedium),
          Text(
            'Expira em: ${_formatDateTime(convite.expiresAt)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: MetricSlateSpacing.sm),
          Text(
            'O código do convite foi exibido na tela após a criação. '
            'Se não copiou, gere um novo convite.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: MetricSlateSpacing.lg),
          FilledButton.icon(
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  subject: 'Convite TechReport',
                  text:
                      'Convite TechReport\n\n'
                      'Nome: ${convite.nome}\n'
                      'E-mail: ${convite.email}\n\n'
                      'O código foi exibido após a criação do convite. '
                      'Se não copiou, gere um novo convite no app.',
                ),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartilhar'),
          ),
          const SizedBox(height: MetricSlateSpacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}
