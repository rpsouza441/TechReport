import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/presentation/view_models/app_admin_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';

class AppAdminArea extends StatefulWidget {
  const AppAdminArea({super.key, required this.viewModel});

  final AppAdminViewModel viewModel;

  @override
  State<AppAdminArea> createState() => _AppAdminAreaState();
}

class _AppAdminAreaState extends State<AppAdminArea> {
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
        return RefreshIndicator(
          onRefresh: widget.viewModel.load,
          child: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.viewModel.isLoading && widget.viewModel.empresas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = widget.viewModel.errorMessage;
    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(MetricSlateSpacing.lg),
        children: [TechReportErrorBanner(message: errorMessage)],
      );
    }

    if (widget.viewModel.empresas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          TechReportStateView.empty(
            title: 'Sem empresas',
            message: 'Nenhuma empresa encontrada.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(MetricSlateSpacing.md),
      itemCount: widget.viewModel.empresas.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: MetricSlateSpacing.sm),
      itemBuilder: (context, index) {
        final empresa = widget.viewModel.empresas[index];
        return _EmpresaCard(empresa: empresa);
      },
    );
  }
}

class _EmpresaCard extends StatelessWidget {
  const _EmpresaCard({required this.empresa});

  final AdminEmpresaResumo empresa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TechReportCard(
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
          TechReportStatusChip(
            label: empresa.ativo ? 'Ativa' : 'Inativa',
            tone: empresa.ativo
                ? TechReportStatusTone.success
                : TechReportStatusTone.neutral,
          ),
        ],
      ),
    );
  }
}
