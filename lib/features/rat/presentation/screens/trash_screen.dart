import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/presentation/view_models/trash_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/trash_view_model.dart';
import 'package:techreport/features/rat/presentation/widgets/trash_rat_card.dart';
import 'package:techreport/shared/presentation/widgets/hierarchical_background.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_confirmation_dialog.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_state_view.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({
    super.key,
    required this.viewModel,
    this.hasSignature,
    this.ownerName,
    this.onOpenDetails,
  });

  final TrashViewModel viewModel;
  final bool Function(Rat rat)? hasSignature;
  final String? Function(Rat rat)? ownerName;
  final ValueChanged<Rat>? onOpenDetails;

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
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
        appBar: AppBar(title: Text(_title)),
        body: HierarchicalBackground(child: _body(context)),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final viewModel = widget.viewModel;
    if (viewModel.isLoading && viewModel.rats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.isAccessDenied) {
      return TechReportStateView.error(
        title: 'Acesso negado',
        message:
            viewModel.errorMessage ??
            'Você não tem permissão para acessar este conteúdo.',
        primaryAction: FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Voltar para RATs'),
        ),
      );
    }
    if (viewModel.rats.isEmpty && viewModel.errorMessage != null) {
      return TechReportStateView.error(
        message: viewModel.errorMessage!,
        primaryAction: FilledButton(
          onPressed: viewModel.load,
          child: const Text('Tentar novamente'),
        ),
      );
    }
    if (viewModel.rats.isEmpty) {
      return const TechReportStateView.empty(
        title: 'Lixeira vazia',
        message: 'Nenhuma RAT foi movida para a lixeira.',
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(MetricSlateSpacing.md),
        itemCount:
            viewModel.rats.length +
            (viewModel.hasMore ? 1 : 0) +
            (viewModel.errorMessage == null ? 0 : 1),
        separatorBuilder: (_, _) =>
            const SizedBox(height: MetricSlateSpacing.sm),
        itemBuilder: (context, index) {
          if (viewModel.errorMessage != null && index == 0) {
            return TechReportErrorBanner(message: viewModel.errorMessage!);
          }
          final dataIndex = index - (viewModel.errorMessage == null ? 0 : 1);
          if (dataIndex == viewModel.rats.length) {
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
          final rat = viewModel.rats[dataIndex];
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: TrashRatCard(
              rat: rat,
              hasSignature: widget.hasSignature?.call(rat) ?? false,
              ownerName: widget.ownerName?.call(rat),
              showOwner: viewModel.scope is CompanyManagerTrashScope,
              showSyncStatus: viewModel.scope is! LocalTrashScope,
              isRestoring: viewModel.restoringRatIds.contains(rat.id),
              onOpenDetails: () => widget.onOpenDetails?.call(rat),
              onRestore: () => _confirmRestore(rat),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRestore(Rat rat) async {
    final isSuperior = widget.viewModel.scope is CompanyManagerTrashScope;
    final confirmed = await showTechReportConfirmationDialog(
      context: context,
      title: 'Restaurar RAT',
      message:
          'A RAT voltará para a lista ativa com status e assinatura '
          'preservados.${isSuperior ? ' O proprietário da RAT será mantido.' : ''}',
      confirmLabel: 'Restaurar RAT',
      cancelLabel: 'Manter na lixeira',
    );
    if (!confirmed || !mounted) return;

    final result = await widget.viewModel.restore(rat.id);
    if (!mounted) return;
    final message = result == TrashRestoreResult.failure
        ? widget.viewModel.errorMessage
        : widget.viewModel.feedbackMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String get _title => switch (widget.viewModel.scope) {
    LocalTrashScope() => 'Lixeira local',
    CompanyTechnicianTrashScope() => 'Minha lixeira',
    CompanyManagerTrashScope() => 'Lixeira da empresa',
  };
}
