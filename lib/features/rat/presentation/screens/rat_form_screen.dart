import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:techreport/features/signature/presentation/screens/signature_capture_screen.dart';
import 'package:techreport/shared/presentation/widgets/metric_slate_text_field.dart';

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
  late final TextEditingController _responsavelController;
  late final TextEditingController _inicioController;
  late final TextEditingController _terminoController;
  late final TextEditingController _equipamentoController;
  late final TextEditingController _equipamentoObservacaoController;
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
    _responsavelController = TextEditingController(
      text: widget.viewModel.responsavelRecebimento,
    );
    _inicioController = TextEditingController(
      text: widget.viewModel.horarioInicioAtendimento,
    );
    _terminoController = TextEditingController(
      text: widget.viewModel.horarioTerminoAtendimento,
    );
    _equipamentoController = TextEditingController(
      text: widget.viewModel.equipamentoDescricao,
    );
    _equipamentoObservacaoController = TextEditingController(
      text: widget.viewModel.equipamentoObservacao,
    );
    widget.viewModel.loadSignatureStatus();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _descricaoController.dispose();
    _responsavelController.dispose();
    _inicioController.dispose();
    _terminoController.dispose();
    _equipamentoController.dispose();
    _equipamentoObservacaoController.dispose();
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
              actions: [
                if (widget.viewModel.canDelete)
                  IconButton(
                    onPressed:
                        widget.viewModel.isSubmitting ||
                            widget.viewModel.isSharing
                        ? null
                        : _handleDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Excluir RAT',
                  ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MetricSlateTextField(
                      controller: _clienteController,
                      enabled: widget.viewModel.canEdit,
                      label: 'Cliente',
                      onChanged: widget.viewModel.setClienteNome,
                    ),
                    const SizedBox(height: 16),
                    MetricSlateTextField(
                      controller: _responsavelController,
                      enabled: widget.viewModel.canEdit,
                      label: 'Responsavel pelo recebimento',
                      onChanged: widget.viewModel.setResponsavelRecebimento,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: widget.viewModel.canEdit ? _pickDataVisita : null,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data da visita',
                        ),
                        child: Text(_formatDate(widget.viewModel.dataVisita)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MetricSlateTextField(
                            controller: _inicioController,
                            enabled: widget.viewModel.canEdit,
                            keyboardType: TextInputType.datetime,
                            label: 'Inicio (HH:mm)',
                            onChanged:
                                widget.viewModel.setHorarioInicioAtendimento,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricSlateTextField(
                            controller: _terminoController,
                            enabled: widget.viewModel.canEdit,
                            keyboardType: TextInputType.datetime,
                            label: 'Termino (HH:mm)',
                            onChanged:
                                widget.viewModel.setHorarioTerminoAtendimento,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MetricSlateTextField(
                      controller: _descricaoController,
                      enabled: widget.viewModel.canEdit,
                      maxLines: 5,
                      label: 'Descri\u00e7\u00e3o',
                      onChanged: widget.viewModel.setDescricao,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<EquipamentoMovimentoTipo>(
                      initialValue: widget.viewModel.equipamentoMovimentoTipo,
                      decoration: const InputDecoration(
                        labelText: 'Movimentacao de equipamento',
                      ),
                      items: EquipamentoMovimentoTipo.values.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(_movimentoLabel(tipo)),
                        );
                      }).toList(),
                      onChanged: widget.viewModel.canEdit
                          ? (value) {
                              if (value != null) {
                                widget.viewModel.setEquipamentoMovimentoTipo(
                                  value,
                                );
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    MetricSlateTextField(
                      controller: _equipamentoController,
                      enabled: widget.viewModel.canEdit,
                      label: 'Descricao do equipamento',
                      onChanged: widget.viewModel.setEquipamentoDescricao,
                    ),
                    const SizedBox(height: 16),
                    MetricSlateTextField(
                      controller: _equipamentoObservacaoController,
                      enabled: widget.viewModel.canEdit,
                      maxLines: 2,
                      label: 'Observacao do equipamento',
                      onChanged: widget.viewModel.setEquipamentoObservacao,
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
                      onChanged: widget.viewModel.canEdit
                          ? (value) {
                              if (value != null) {
                                widget.viewModel.setStatus(value);
                              }
                            }
                          : null,
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
                        onPressed:
                            widget.viewModel.isSubmitting ||
                                !widget.viewModel.canEdit
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
                                widget.viewModel.isSharing ||
                                !widget.viewModel.canEdit
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
                                widget.viewModel.isSharing ||
                                !widget.viewModel.canEdit
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

  Future<void> _handleDelete() async {
    final shouldDelete = await _confirmDeleteRat();
    if (!shouldDelete || !mounted) {
      return;
    }

    final deleted = await widget.viewModel.deleteRat();
    if (!mounted) {
      return;
    }

    if (deleted) {
      _closeForm(result: true);
    }
  }

  Future<bool> _confirmDeleteRat() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir RAT?'),
          content: const Text(
            'Este RAT sera removido da lista. Em modo empresa, a exclusao sera sincronizada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    return result ?? false;
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

  Future<void> _pickDataVisita() async {
    final now = DateTime.now();
    final initialDate = widget.viewModel.dataVisita ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      widget.viewModel.setDataVisita(picked);
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Selecione';
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _movimentoLabel(EquipamentoMovimentoTipo tipo) {
    switch (tipo) {
      case EquipamentoMovimentoTipo.nenhum:
        return 'Nenhuma movimentacao';
      case EquipamentoMovimentoTipo.retiradaParaReparo:
        return 'Retirada para reparo';
      case EquipamentoMovimentoTipo.entregaPosReparo:
        return 'Entrega pos-reparo';
      case EquipamentoMovimentoTipo.entregaPosCompra:
        return 'Entrega pos-compra';
    }
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
