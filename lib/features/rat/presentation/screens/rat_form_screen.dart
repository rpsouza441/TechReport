import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:techreport/features/signature/presentation/screens/signature_capture_screen.dart';

import '../../domain/entities/rat.dart';
import '../view_models/rat_form_view_model.dart';

class RatFormScreen extends StatefulWidget {
  const RatFormScreen({super.key, required this.viewModel});

  final RatFormViewModel viewModel;

  @override
  State<RatFormScreen> createState() => _RatFormScreenState();
}

class _RatFormScreenState extends State<RatFormScreen> {
  late final TextEditingController _clienteController;
  late final TextEditingController _descricaoController;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _clienteController = TextEditingController(
      text: widget.viewModel.clienteNome,
    );
    _descricaoController = TextEditingController(
      text: widget.viewModel.descricao,
    );
    widget.viewModel.loadSignatureStatus();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return PopScope<bool>(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _closeForm();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: _closeForm),
              title: Text(
                widget.viewModel.isEditing || widget.viewModel.isSaved
                    ? 'Editar RAT'
                    : 'Novo RAT',
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _clienteController,
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      onChanged: widget.viewModel.setClienteNome,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descricaoController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Descri\u00e7\u00e3o',
                        alignLabelWithHint: true,
                      ),
                      onChanged: widget.viewModel.setDescricao,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RatStatus>(
                      initialValue: widget.viewModel.status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: RatStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          widget.viewModel.setStatus(value);
                        }
                      },
                    ),
                    if (widget.viewModel.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.viewModel.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _SignatureStatusCard(viewModel: widget.viewModel),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.viewModel.isSubmitting
                            ? null
                            : _handleSignature,
                        icon: const Icon(Icons.draw),
                        label: Text(
                          widget.viewModel.hasSignature
                              ? 'Substituir assinatura'
                              : 'Capturar assinatura',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            widget.viewModel.isSubmitting ||
                                widget.viewModel.isSharing
                            ? null
                            : _handleSharePdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(
                          widget.viewModel.isSharing
                              ? 'Preparando PDF...'
                              : 'Compartilhar PDF',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            widget.viewModel.isSubmitting ||
                                widget.viewModel.isSharing
                            ? null
                            : _handleSubmit,
                        child: Text(
                          widget.viewModel.isSubmitting
                              ? 'Salvando...'
                              : 'Salvar RAT',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    await widget.viewModel.submit();

    if (!mounted) {
      return;
    }

    if (widget.viewModel.errorMessage == null) {
      _closeForm(result: true);
    }
  }

  Future<void> _handleSignature() async {
    if (widget.viewModel.hasSignature) {
      final shouldReplace = await _confirmReplaceSignature();
      if (!shouldReplace || !mounted) {
        return;
      }
    }

    final saved = await widget.viewModel.save();
    if (!mounted || !saved) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atendimento salvo. Abrindo assinatura...')),
    );

    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const SignatureCaptureScreen()),
    );

    if (!mounted || bytes == null) {
      return;
    }

    final signatureSaved = await widget.viewModel.saveSignature(bytes);
    if (!mounted) {
      return;
    }

    if (signatureSaved) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Assinatura capturada.')));
    }
  }

  Future<bool> _confirmReplaceSignature() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Substituir assinatura?'),
          content: const Text(
            'Este RAT j\u00e1 possui uma assinatura salva. Ao continuar, a assinatura atual ser\u00e1 substitu\u00edda.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _handleSharePdf() async {
    final shared = await widget.viewModel.sharePdf();
    if (!mounted) {
      return;
    }

    if (shared) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF pronto para envio.')));
    }
  }

  void _closeForm({bool? result}) {
    if (!mounted) {
      return;
    }

    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop(result ?? widget.viewModel.shouldReloadOnClose);
  }
}

class _SignatureStatusCard extends StatelessWidget {
  const _SignatureStatusCard({required this.viewModel});

  final RatFormViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (viewModel.isLoadingSignature) {
      return const LinearProgressIndicator();
    }

    final previewBytes = viewModel.signaturePreviewBytes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  viewModel.hasSignature
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: viewModel.hasSignature
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  viewModel.hasSignature
                      ? 'Assinatura salva'
                      : 'Nenhuma assinatura salva',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            if (previewBytes != null) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.memory(
                      previewBytes,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
