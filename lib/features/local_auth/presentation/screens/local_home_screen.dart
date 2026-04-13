import 'package:flutter/material.dart';
import 'package:techreport/features/rat/domain/repositories/drift_rat_repository.dart';
import 'package:techreport/features/rat/presentation/screens/rat_form_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_form_view_model.dart';
import 'package:techreport/shared/infra/database/tech_report_local_database.dart';

import '../view_models/app_session_view_model.dart';

class LocalHomeScreen extends StatelessWidget {
  const LocalHomeScreen({super.key, required this.viewModel});

  final AppSessionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tech Report'),
        actions: [
          if (viewModel.pinConfigured)
            TextButton(
              onPressed: viewModel.lock,
              child: const Text('Bloquear'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shell local pronto',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A sprint 1 fica dentro do escopo quando o app consegue '
                      'decidir entre onboarding, unlock e area liberada sem '
                      'encostar em backend, RAT ou sync.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        final database = TechReportLocalDatabase();
                        final ratRepository = DriftRatRepository(database);

                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RatFormScreen(
                              viewModel: RatFormViewModel(
                                ratRepository: ratRepository,
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Novo RAT'),
                    ),
                    const SizedBox(height: 20),
                    const _StatusChip(label: 'Modo local'),
                    const SizedBox(height: 12),
                    const _StatusChip(label: 'Sessao desbloqueada'),
                    const SizedBox(height: 12),
                    const _StatusChip(label: 'UI desacoplada de persistencia'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(label),
      ),
    );
  }
}
