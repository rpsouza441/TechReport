import 'package:flutter/material.dart';
import 'package:techreport/features/company_auth/presentation/view_models/app_mode_choice_view_model.dart';

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
          appBar: AppBar(title: const Text('TechReport')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Como voce quer comecar?',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Use um servidor da empresa ou mantenha tudo apenas neste dispositivo.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          viewModel.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: viewModel.isSaving
                            ? null
                            : () => _chooseCompany(context),
                        child: viewModel.isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Conectar ao servidor'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: viewModel.isSaving
                            ? null
                            : () => _chooseLocal(context),
                        child: const Text('Criar conta local'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _chooseCompany(BuildContext context) async {
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
