import 'package:flutter/material.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

import '../../domain/entities/rat.dart';
import '../../domain/repositories/rat_repository.dart';
import '../../presentation/view_models/rat_form_view_model.dart';
import '../../presentation/view_models/rat_list_view_model.dart';
import 'rat_form_screen.dart';

class RatListScreen extends StatefulWidget {
  const RatListScreen({
    super.key,
    required this.assinaturaRepository,
    required this.localSignatureAssetStore,
    required this.ratPdfShareService,
    required this.viewModel,
    required this.ratRepository,
    required this.shareRatLocally,
  });

  final AssinaturaRepository assinaturaRepository;
  final LocalSignatureAssetStore localSignatureAssetStore;
  final RatPdfShareService ratPdfShareService;
  final RatListViewModel viewModel;
  final RatRepository ratRepository;
  final ShareRatLocally shareRatLocally;

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
                  final hasSignature = widget.viewModel.hasSignature(rat.id);
                  return Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(rat.clienteNome)),
                          if (hasSignature) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.draw,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(rat.descricao),
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
          viewModel: RatFormViewModel(
            assinaturaRepository: widget.assinaturaRepository,
            localSignatureAssetStore: widget.localSignatureAssetStore,
            ratPdfShareService: widget.ratPdfShareService,
            ratRepository: widget.ratRepository,
            shareRatLocally: widget.shareRatLocally,
          ),
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
            assinaturaRepository: widget.assinaturaRepository,
            localSignatureAssetStore: widget.localSignatureAssetStore,
            ratPdfShareService: widget.ratPdfShareService,
            ratRepository: widget.ratRepository,
            shareRatLocally: widget.shareRatLocally,
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
