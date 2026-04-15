import 'package:flutter/material.dart';

import '../../domain/entities/rat.dart';
import '../../domain/repositories/rat_repository.dart';
import '../../presentation/view_models/rat_form_view_model.dart';
import '../../presentation/view_models/rat_list_view_model.dart';
import 'rat_form_screen.dart';

class RatListScreen extends StatefulWidget {
  const RatListScreen({
    super.key,
    required this.viewModel,
    required this.ratRepository,
  });

  final RatListViewModel viewModel;
  final RatRepository ratRepository;

  @override
  State<RatListScreen> createState() => _RatListScreenState();
}

class _RatListScreenState extends State<RatListScreen> {
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
        return Scaffold(
          appBar: AppBar(title: const Text('RATs')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: const Text('Novo RAT'),
          ),
          body: Builder(
            builder: (context) {
              if (widget.viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (widget.viewModel.errorMessage != null) {
                return Center(child: Text(widget.viewModel.errorMessage!));
              }

              if (widget.viewModel.isEmpty) {
                return const Center(
                  child: Text('Nenhum RAT cadastrado ainda.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.viewModel.rats.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final rat = widget.viewModel.rats[index];
                  return Card(
                    child: ListTile(
                      title: Text(rat.clienteNome),
                      subtitle: Text('${rat.numero} • ${rat.descricao}'),
                      trailing: Text(rat.status.name),
                      onTap: () => _openEdit(rat),
                    ),
                  );
                },
              );
            },
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
      await widget.viewModel.load();
    }
  }

  Future<void> _openEdit(Rat rat) async {
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
      await widget.viewModel.load();
    }
  }
}
