import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_audit_view_model.dart';
import 'package:techreport/features/rat/presentation/widgets/rat_audit_event_card.dart';
import 'package:techreport/shared/presentation/widgets/hierarchical_background.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_info_row.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_status_chip.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';

class RatAuditScreen extends StatefulWidget {
  const RatAuditScreen({
    super.key,
    required this.viewModel,
    required this.rat,
    required this.ownerName,
    required this.hasSignature,
    this.currentUserId,
  });

  final RatAuditViewModel viewModel;
  final Rat rat;
  final String ownerName;
  final bool hasSignature;
  final String? currentUserId;

  @override
  State<RatAuditScreen> createState() => _RatAuditScreenState();
}

class _RatAuditScreenState extends State<RatAuditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.viewModel.load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Histórico da RAT')),
        body: HierarchicalBackground(child: _body(context)),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final viewModel = widget.viewModel;
    if (viewModel.events.isNotEmpty) return _timeline();

    return switch (viewModel.status) {
      RatAuditViewStatus.initial || RatAuditViewStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      RatAuditViewStatus.empty => const TechReportStateView.empty(
        title: 'Nenhuma alteração registrada',
        message: 'Ainda não há alterações registradas para esta RAT.',
      ),
      RatAuditViewStatus.offline => const TechReportStateView(
        title: 'Sem conexão',
        message:
            'Histórico indisponível sem conexão. Alterações pendentes '
            'aparecerão após a sincronização.',
        icon: Icons.cloud_off_outlined,
      ),
      RatAuditViewStatus.accessDenied => TechReportStateView.error(
        title: 'Acesso negado',
        message: 'Você não tem permissão para acessar este conteúdo.',
        primaryAction: FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Voltar para RATs'),
        ),
      ),
      RatAuditViewStatus.error => TechReportStateView.error(
        message: 'Não foi possível carregar o histórico. Tente novamente.',
        primaryAction: FilledButton(
          onPressed: viewModel.load,
          child: const Text('Tentar novamente'),
        ),
      ),
      RatAuditViewStatus.content => _timeline(),
    };
  }

  Widget _timeline() {
    final viewModel = widget.viewModel;
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 600
              ? MetricSlateSpacing.md
              : MetricSlateSpacing.lg;
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontal,
              MetricSlateSpacing.md,
              horizontal,
              MetricSlateSpacing.lg,
            ),
            itemCount:
                1 +
                viewModel.events.length +
                (viewModel.failure == null ? 0 : 1) +
                (viewModel.hasMore ? 1 : 0),
            separatorBuilder: (_, _) =>
                const SizedBox(height: MetricSlateSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) return Center(child: _contextCard());
              var dataIndex = index - 1;
              if (viewModel.failure != null) {
                if (dataIndex == 0) {
                  return TechReportErrorBanner(message: _inlineFailureMessage);
                }
                dataIndex--;
              }
              if (dataIndex == viewModel.events.length) {
                return Center(
                  child: viewModel.isLoadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(MetricSlateSpacing.md),
                          child: CircularProgressIndicator(),
                        )
                      : TextButton(
                          onPressed: viewModel.loadMore,
                          child: const Text('Carregar mais'),
                        ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: RatAuditEventCard(
                    event: viewModel.events[dataIndex],
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _contextCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: TechReportCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'RAT ${widget.rat.numero}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            TechReportInfoRow(label: 'Cliente', value: widget.rat.clienteNome),
            TechReportInfoRow(
              label: 'Proprietário',
              value: widget.ownerName.trim().isEmpty
                  ? 'Proprietário não identificado'
                  : widget.ownerName,
            ),
            const SizedBox(height: MetricSlateSpacing.xs),
            Wrap(
              spacing: MetricSlateSpacing.xs,
              runSpacing: MetricSlateSpacing.xs,
              children: [
                TechReportStatusChip(
                  label: ratStatusLabel(widget.rat.status),
                  tone: ratStatusTone(widget.rat.status),
                ),
                TechReportStatusChip(
                  label: widget.hasSignature ? 'Assinada' : 'Sem assinatura',
                  tone: widget.hasSignature
                      ? TechReportStatusTone.success
                      : TechReportStatusTone.neutral,
                  icon: widget.hasSignature ? Icons.draw : Icons.draw_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _inlineFailureMessage => switch (widget.viewModel.failure) {
    RatAuditFailure.offline =>
      'Sem conexão. O histórico exibido pode não incluir alterações recentes.',
    RatAuditFailure.accessDenied =>
      'Você não tem permissão para acessar este conteúdo.',
    RatAuditFailure.load ||
    null => 'Não foi possível atualizar o histórico. Tente novamente.',
  };
}
