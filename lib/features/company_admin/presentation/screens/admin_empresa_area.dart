import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/presentation/view_models/admin_empresa_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
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
        return RefreshIndicator(
          onRefresh: widget.viewModel.load,
          child: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.viewModel.isLoading && widget.viewModel.tecnicos.isEmpty) {
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

    if (widget.viewModel.tecnicos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          TechReportStateView.empty(
            title: 'Equipe vazia',
            message: 'Nenhum técnico encontrado.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(MetricSlateSpacing.md),
      itemCount: widget.viewModel.tecnicos.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: MetricSlateSpacing.sm),
      itemBuilder: (context, index) {
        final tecnico = widget.viewModel.tecnicos[index];
        return _TecnicoCard(tecnico: tecnico);
      },
    );
  }
}

class _TecnicoCard extends StatelessWidget {
  const _TecnicoCard({required this.tecnico});

  final AdminTecnicoResumo tecnico;

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
                Text(
                  tecnico.email,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: MetricSlateSpacing.xxs),
                Text(
                  _papelLabel(tecnico.papel),
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          TechReportStatusChip(
            label: tecnico.ativo ? 'Ativo' : 'Inativo',
            tone: tecnico.ativo
                ? TechReportStatusTone.success
                : TechReportStatusTone.neutral,
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
