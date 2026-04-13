import 'package:flutter/material.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart' as domain;
import 'package:techreport/features/rat/data/repositories/rat_repository.dart';
import 'package:techreport/features/rat/presentation/screens/rat_form_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_form_view_model.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_view_model.dart';

import '../view_models/app_session_view_model.dart';

class LocalHomeScreen extends StatefulWidget {
  const LocalHomeScreen({
    super.key,
    required this.viewModel,
    required this.ratRepository,
  });

  final AppSessionViewModel viewModel;

  final RatRepository ratRepository;

  @override
  State<LocalHomeScreen> createState() => _LocalHomeScreenState();
}

class _LocalHomeScreenState extends State<LocalHomeScreen> {
  late final RatListViewModel _ratListViewModel;

  @override
  void initState() {
    super.initState();

    _ratListViewModel = RatListViewModel(ratRepository: widget.ratRepository);
    _ratListViewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _ratListViewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tech Report'),
            actions: [
              if (widget.viewModel.pinConfigured)
                TextButton(
                  onPressed: widget.viewModel.lock,
                  child: const Text('Bloquear'),
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seus RATs locais',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie, acompanhe e edite atendimentos salvos neste dispositivo.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _openCreate,
                        icon: const Icon(Icons.add),
                        label: const Text('Novo RAT'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _ratListViewModel.load,
                        child: const Text('Atualizar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (_ratListViewModel.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (_ratListViewModel.errorMessage != null) {
                          return Center(
                            child: Text(_ratListViewModel.errorMessage!),
                          );
                        }

                        if (_ratListViewModel.isEmpty) {
                          return _EmptyRatState(onCreate: _openCreate);
                        }

                        return ListView.separated(
                          itemCount: _ratListViewModel.rats.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final rat = _ratListViewModel.rats[index];
                            return Card(
                              child: ListTile(
                                title: Text(rat.clienteNome),
                                subtitle: Text(
                                  '${rat.numero} • ${rat.descricao}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(rat.status.name),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(rat.updatedAt),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                onTap: () => _openEdit(rat),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreate() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RatFormScreen(
          viewModel: RatFormViewModel(ratRepository: widget.ratRepository),
        ),
      ),
    );

    if (result == true) {
      await _ratListViewModel.load();
    }
  }

  Future<void> _openEdit(domain.Rat rat) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RatFormScreen(
          viewModel: RatFormViewModel(
            ratRepository: widget.ratRepository,
            initialRat: rat,
          ),
        ),
      ),
    );

    if (result == true) {
      await _ratListViewModel.load();
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

class _EmptyRatState extends StatelessWidget {
  const _EmptyRatState({required this.onCreate});

  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Nenhum RAT criado ainda',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Comece criando o primeiro atendimento local do dispositivo.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onCreate,
                  child: const Text('Criar primeiro RAT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
