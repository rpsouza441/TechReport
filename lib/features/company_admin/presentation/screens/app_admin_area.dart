import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/domain/usecases/cancel_tecnico_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/create_empresa_convite.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_empresa_admin_convites.dart';
import 'package:techreport/features/company_admin/domain/usecases/list_empresa_admins.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_admin_empresa.dart';
import 'package:techreport/features/company_admin/domain/usecases/update_empresa_admin.dart';
import 'package:techreport/features/company_admin/presentation/screens/app_admin_company_detail_screen.dart';
import 'package:techreport/features/company_admin/presentation/screens/app_admin_company_form_screen.dart';
import 'package:techreport/features/company_admin/presentation/view_models/app_admin_company_detail_view_model.dart';
import 'package:techreport/features/company_admin/presentation/view_models/app_admin_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';

class AppAdminArea extends StatefulWidget {
  const AppAdminArea({
    super.key,
    required this.viewModel,
    required this.listEmpresaAdmins,
    required this.listEmpresaAdminConvites,
    required this.createEmpresaConvite,
    required this.cancelTecnicoConvite,
    required this.updateEmpresaAdmin,
    required this.updateAdminEmpresa,
  });

  final AppAdminViewModel viewModel;
  final ListEmpresaAdmins listEmpresaAdmins;
  final ListEmpresaAdminConvites listEmpresaAdminConvites;
  final CreateEmpresaConvite createEmpresaConvite;
  final CancelTecnicoConvite cancelTecnicoConvite;
  final UpdateEmpresaAdmin updateEmpresaAdmin;
  final UpdateAdminEmpresa updateAdminEmpresa;

  @override
  State<AppAdminArea> createState() => _AppAdminAreaState();
}

class _AppAdminAreaState extends State<AppAdminArea> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            Positioned(
              right: MetricSlateSpacing.lg,
              bottom: MetricSlateSpacing.lg,
              child: FloatingActionButton.extended(
                onPressed: widget.viewModel.isSubmitting
                    ? null
                    : _openCreateEmpresaScreen,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Empresa'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.viewModel.isLoading && widget.viewModel.empresas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = widget.viewModel.errorMessage;
    final empresas = _filteredEmpresas();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        MetricSlateSpacing.md,
        MetricSlateSpacing.md,
        MetricSlateSpacing.md,
        88,
      ),
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Pesquisar empresa',
            prefixIcon: const Icon(Icons.search_outlined),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.close_outlined),
                    tooltip: 'Limpar',
                  ),
          ),
        ),
        const SizedBox(height: MetricSlateSpacing.md),
        if (errorMessage != null) ...[
          TechReportErrorBanner(message: errorMessage),
          const SizedBox(height: MetricSlateSpacing.sm),
        ],
        if (widget.viewModel.empresas.isEmpty)
          const TechReportStateView.empty(
            title: 'Sem empresas',
            message: 'Crie a primeira empresa pelo botao abaixo.',
          )
        else if (empresas.isEmpty)
          const TechReportStateView.empty(
            title: 'Nada encontrado',
            message: 'Ajuste a pesquisa para ver empresas.',
          )
        else
          for (final empresa in empresas) ...[
            _EmpresaCard(
              empresa: empresa,
              isSubmitting: widget.viewModel.isSubmitting,
              onTap: () => _openDetailScreen(empresa),
              onInviteAdmin: () => _openInviteAdminScreen(empresa),
              onToggleAtivo: (ativo) => widget.viewModel.setEmpresaAtiva(
                empresa: empresa,
                ativo: ativo,
              ),
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
          ],
      ],
    );
  }

  List<AdminEmpresaResumo> _filteredEmpresas() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.viewModel.empresas;
    }

    return widget.viewModel.empresas
        .where((empresa) => empresa.nome.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _openCreateEmpresaScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AppAdminCreateCompanyScreen(viewModel: widget.viewModel),
      ),
    );

    if (!mounted || created != true) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Empresa criada.')));
  }

  Future<void> _openInviteAdminScreen(AdminEmpresaResumo empresa) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppAdminInviteCompanyAdminScreen(
          viewModel: widget.viewModel,
          empresa: empresa,
        ),
      ),
    );
  }

  Future<void> _openDetailScreen(AdminEmpresaResumo empresa) async {
    final updatedEmpresa = await Navigator.of(context).push<AdminEmpresaResumo>(
      MaterialPageRoute(
        builder: (_) => AppAdminCompanyDetailScreen(
          viewModel: AppAdminCompanyDetailViewModel(
            empresa: empresa,
            listEmpresaAdmins: widget.listEmpresaAdmins,
            listEmpresaAdminConvites: widget.listEmpresaAdminConvites,
            createEmpresaConvite: widget.createEmpresaConvite,
            cancelTecnicoConvite: widget.cancelTecnicoConvite,
            updateEmpresaAdmin: widget.updateEmpresaAdmin,
            updateAdminEmpresa: widget.updateAdminEmpresa,
          ),
        ),
      ),
    );

    if (!mounted || updatedEmpresa == null) return;

    widget.viewModel.syncEmpresa(updatedEmpresa);
  }
}

class _EmpresaCard extends StatelessWidget {
  const _EmpresaCard({
    required this.empresa,
    required this.isSubmitting,
    required this.onTap,
    required this.onInviteAdmin,
    required this.onToggleAtivo,
  });

  final AdminEmpresaResumo empresa;
  final bool isSubmitting;
  final VoidCallback onTap;
  final VoidCallback onInviteAdmin;
  final ValueChanged<bool> onToggleAtivo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
      onTap: isSubmitting ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(empresa.nome, style: theme.textTheme.titleMedium),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(
                  empresa.ativo ? 'Empresa ativa' : 'Empresa inativa',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ActionChip(
                label: Text(empresa.ativo ? 'Ativa' : 'Inativa'),
                avatar: Icon(
                  empresa.ativo ? Icons.check_circle : Icons.cancel_outlined,
                  size: 16,
                  color: empresa.ativo
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                onPressed: isSubmitting
                    ? null
                    : () => onToggleAtivo(!empresa.ativo),
              ),
              const SizedBox(height: MetricSlateSpacing.xxs),
              PopupMenuButton<String>(
                enabled: !isSubmitting,
                onSelected: (value) {
                  switch (value) {
                    case 'invite_admin':
                      onInviteAdmin();
                    case 'activate':
                      onToggleAtivo(true);
                    case 'deactivate':
                      onToggleAtivo(false);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'invite_admin',
                    child: Text('Convidar admin'),
                  ),
                  if (!empresa.ativo)
                    const PopupMenuItem(
                      value: 'activate',
                      child: Text('Ativar'),
                    ),
                  if (empresa.ativo)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Text('Inativar'),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
