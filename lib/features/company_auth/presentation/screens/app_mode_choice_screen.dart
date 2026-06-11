import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_auth/presentation/view_models/app_mode_choice_view_model.dart';
import 'package:techreport/shared/presentation/widgets/hierarchical_background.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';

class AppModeChoiceScreen extends StatelessWidget {
  const AppModeChoiceScreen({
    super.key,
    required this.viewModel,
    required this.onCompanySelected,
    required this.onLocalSelected,
  });

  final AppModeChoiceViewModel viewModel;
  final VoidCallback onCompanySelected;
  final VoidCallback onLocalSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: HierarchicalBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: MetricSlateSpacing.xl),
                      _ModeCard(
                        icon: Icons.smartphone_outlined,
                        title: 'Modo Local',
                        description:
                            'Todos os dados ficam neste dispositivo. '
                            'Sem conexão com servidor, sem sincronização. '
                            'Ideal para trabalho offline ou ambientes sem internet.',
                        buttonLabel: 'Usar modo local',
                        isLoading: viewModel.isSaving,
                        onTap: () => _chooseLocal(context),
                      ),
                      const SizedBox(height: MetricSlateSpacing.md),
                      _ModeCard(
                        icon: Icons.cloud_outlined,
                        title: 'Modo Empresa',
                        description:
                            'Relatórios sincronizam com o servidor da empresa. '
                            'Acesso compartilhado, backup na nuvem e '
                            'equipe conectada.',
                        buttonLabel: 'Conectar ao servidor',
                        isLoading: viewModel.isSaving,
                        onTap: () => _chooseCompany(context),
                      ),
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: MetricSlateSpacing.md),
                        Text(
                          viewModel.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(Icons.analytics_outlined, size: 48, color: scheme.primary),
        const SizedBox(height: MetricSlateSpacing.md),
        Text(
          'TechReport',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MetricSlateSpacing.xs),
        Text(
          'Como você quer começar?',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _chooseCompany(BuildContext context) async {
    // viewModel.chooseCompany() salva o modo (AppMode.company) no storage.
    // onCompanySelected chama bootstrapViewModel.chooseCompany() que verifica
    // endpoint salvo e decide: remoteLoginRequired ou remoteEndpointRequired.
    final success = await viewModel.chooseCompany();
    if (success && context.mounted) {
      onCompanySelected();
    }
  }

  Future<void> _chooseLocal(BuildContext context) async {
    final success = await viewModel.chooseLocal();
    if (success && context.mounted) {
      onLocalSelected();
    }
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TechReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 28, color: scheme.primary),
              const SizedBox(width: MetricSlateSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: MetricSlateSpacing.sm),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: MetricSlateSpacing.md),
          FilledButton(
            onPressed: isLoading ? null : onTap,
            child: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
