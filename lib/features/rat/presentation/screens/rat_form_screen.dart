import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show TextEditingValue, TextInputFormatter;
import 'package:techreport/app/theme/metric_slate_radii.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/rat/presentation/rat_ui_labels.dart';
import 'package:techreport/features/rat/presentation/screens/rat_pdf_preview_screen.dart';
import 'package:techreport/features/rat/presentation/screens/rat_reopen_reason_screen.dart';
import 'package:techreport/features/signature/presentation/screens/signature_capture_screen.dart';
import 'package:techreport/shared/presentation/widgets/metric_slate_text_field.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_discard_dialog.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_section_header.dart';

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
  late final TextEditingController _responsavelDocumentoController;
  late final TextEditingController _inicioController;
  late final TextEditingController _terminoController;
  late final TextEditingController _equipamentoController;
  late final TextEditingController _equipamentoObservacaoController;
  bool _allowPop = false;
  bool _hasUnsavedChanges = false;

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
    _responsavelDocumentoController = TextEditingController(
      text: widget.viewModel.responsavelDocumento,
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

    // Track unsaved changes
    for (final controller in [
      _clienteController,
      _descricaoController,
      _responsavelController,
      _responsavelDocumentoController,
      _inicioController,
      _terminoController,
      _equipamentoController,
      _equipamentoObservacaoController,
    ]) {
      controller.addListener(_onFormChanged);
    }

    widget.viewModel.loadSignatureStatus();
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _descricaoController.dispose();
    _responsavelController.dispose();
    _responsavelDocumentoController.dispose();
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
        final scheme = Theme.of(context).colorScheme;
        final vm = widget.viewModel;
        final isBusy = vm.isSubmitting || vm.isSharing;

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
                vm.isEditing || vm.isSaved ? 'Editar RAT' : 'Novo RAT',
              ),
              actions: [
                if (vm.canDelete)
                  IconButton(
                    onPressed: isBusy ? null : _handleDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Excluir RAT',
                  ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (vm.isReadOnly)
                      Container(
                        margin: const EdgeInsets.only(
                          bottom: MetricSlateSpacing.md,
                        ),
                        padding: const EdgeInsets.all(MetricSlateSpacing.sm),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: MetricSlateSpacing.xs),
                            Expanded(
                              child: Text(
                                'Somente leitura — você não pode editar esta RAT.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _FormSection(
                      title: 'Cliente e visita',
                      children: [
                        MetricSlateTextField(
                          controller: _clienteController,
                          enabled: vm.canEditFields,
                          label: 'Cliente',
                          onChanged: vm.setClienteNome,
                        ),
                        const SizedBox(height: MetricSlateSpacing.md),
                        MetricSlateTextField(
                          controller: _responsavelController,
                          enabled: vm.canEditFields,
                          label: 'Responsável pelo recebimento',
                          onChanged: vm.setResponsavelRecebimento,
                        ),
                        const SizedBox(height: MetricSlateSpacing.md),
                        MetricSlateTextField(
                          controller: _responsavelDocumentoController,
                          enabled: vm.canEditFields,
                          label: 'Documento do responsável (opcional)',
                          onChanged: vm.setResponsavelDocumento,
                        ),
                        const SizedBox(height: MetricSlateSpacing.md),
                        InkWell(
                          onTap: vm.canEditFields ? _pickDataVisita : null,
                          borderRadius: BorderRadius.circular(
                            MetricSlateRadii.sm,
                          ),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data da visita',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(_formatDate(vm.dataVisita)),
                          ),
                        ),
                        const SizedBox(height: MetricSlateSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: MetricSlateTextField(
                                controller: _inicioController,
                                enabled: vm.canEditFields,
                                keyboardType: TextInputType.number,
                                inputFormatters: const [
                                  _HourTextInputFormatter(),
                                ],
                                label: 'Início (HH:mm)',
                                onChanged: vm.setHorarioInicioAtendimento,
                              ),
                            ),
                            const SizedBox(width: MetricSlateSpacing.sm),
                            Expanded(
                              child: MetricSlateTextField(
                                controller: _terminoController,
                                enabled: vm.canEditFields,
                                keyboardType: TextInputType.number,
                                inputFormatters: const [
                                  _HourTextInputFormatter(),
                                ],
                                label: 'Término (HH:mm)',
                                onChanged: vm.setHorarioTerminoAtendimento,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _FormSection(
                      title: 'Atendimento',
                      children: [
                        MetricSlateTextField(
                          controller: _descricaoController,
                          enabled: vm.canEditFields,
                          maxLines: 5,
                          label: 'Descrição',
                          onChanged: vm.setDescricao,
                        ),
                      ],
                    ),
                    _FormSection(
                      title: 'Equipamento',
                      children: [
                        DropdownButtonFormField<EquipamentoMovimentoTipo>(
                          key: ValueKey(vm.equipamentoMovimentoTipo),
                          initialValue: vm.equipamentoMovimentoTipo,
                          decoration: const InputDecoration(
                            labelText: 'Movimentação de equipamento',
                            prefixIcon: Icon(
                              Icons.precision_manufacturing_outlined,
                            ),
                          ),
                          items: EquipamentoMovimentoTipo.values.map((tipo) {
                            return DropdownMenuItem(
                              value: tipo,
                              child: Text(equipamentoMovimentoLabel(tipo)),
                            );
                          }).toList(),
                          onChanged: vm.canEditFields
                              ? (value) {
                                  if (value != null) {
                                    vm.setEquipamentoMovimentoTipo(value);
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: MetricSlateSpacing.md),
                        MetricSlateTextField(
                          controller: _equipamentoController,
                          enabled: vm.canEditFields,
                          label: 'Descrição do equipamento',
                          onChanged: vm.setEquipamentoDescricao,
                        ),
                        const SizedBox(height: MetricSlateSpacing.md),
                        MetricSlateTextField(
                          controller: _equipamentoObservacaoController,
                          enabled: vm.canEditFields,
                          maxLines: 2,
                          label: 'Observação do equipamento',
                          onChanged: vm.setEquipamentoObservacao,
                        ),
                      ],
                    ),
                    _FormSection(
                      title: 'Status',
                      children: [
                        DropdownButtonFormField<RatStatus>(
                          key: ValueKey(vm.status),
                          initialValue: vm.status,
                          decoration: const InputDecoration(
                            labelText: 'Status do RAT',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: RatStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(ratStatusLabel(status)),
                            );
                          }).toList(),
                          onChanged: vm.canEditFields
                              ? (value) {
                                  if (value != null) {
                                    vm.setStatus(value);
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                    if (vm.canReopenForCorrection) ...[
                      _FormSection(
                        title: 'Correção',
                        children: [
                          Text(
                            'Reabra este RAT para alterar os dados operacionais. A assinatura atual deixará de valer e uma nova assinatura será necessária.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: MetricSlateSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : _handleReopenForCorrection,
                              icon: const Icon(Icons.lock_open_outlined),
                              label: const Text('Reabrir para correção'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: MetricSlateSpacing.md),
                      TechReportErrorBanner(message: vm.errorMessage!),
                    ],
                    const SizedBox(height: MetricSlateSpacing.md),
                    _FormSection(
                      title: 'Assinatura',
                      children: [
                        _buildSignatureSection(context),
                        const SizedBox(height: MetricSlateSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isBusy || !vm.canEditFields
                                ? null
                                : _handleSignature,
                            icon: const Icon(Icons.draw_outlined),
                            label: Text(
                              vm.hasValidSignature
                                  ? 'Substituir assinatura'
                                  : 'Capturar assinatura',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MetricSlateSpacing.md),
                    OutlinedButton.icon(
                      onPressed: isBusy || !vm.canPreviewPdf
                          ? null
                          : _handleSharePdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        vm.isSharing ? 'Preparando...' : 'Prévia do PDF',
                      ),
                    ),
                    const SizedBox(height: MetricSlateSpacing.sm),
                    FilledButton.icon(
                      onPressed: isBusy || !vm.canEditFields
                          ? null
                          : _handleSubmit,
                      icon: vm.isSubmitting
                          ? SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 20),
                      label: Text(
                        vm.isSubmitting ? 'Salvando...' : 'Salvar RAT',
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
      setState(() => _hasUnsavedChanges = false);
      _closeForm(result: true);
    }
  }

  Future<void> _handleSignature() async {
    if (widget.viewModel.hasValidSignature) {
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
            'Este RAT já possui uma assinatura salva. Ao continuar, a assinatura atual será substituída.',
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
    final previewData = await widget.viewModel.prepareForPdfPreview(
      persist: widget.viewModel.canEditFields,
    );
    if (!mounted || previewData == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RatPdfPreviewScreen(
          rat: previewData.rat,
          signatureBytes: previewData.signatureBytes,
          assinaturaPendente: previewData.assinaturaPendente,
          empresaNome: previewData.empresaNome,
          tecnicoNome: previewData.tecnicoNome,
          onShare: () async {
            await widget.viewModel.sharePdf();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF pronto para envio.')),
              );
            }
          },
          onSave: () async {
            final exported = await widget.viewModel.savePdf();
            if (!mounted) {
              return;
            }
            if (exported) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF salvo no dispositivo.')),
              );
            } else if (widget.viewModel.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(widget.viewModel.errorMessage!)),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleReopenForCorrection() async {
    final motivo = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RatReopenReasonScreen()),
    );
    if (!mounted || motivo == null) {
      return;
    }

    final reopened = await widget.viewModel.reopenForCorrection(motivo);
    if (!mounted) {
      return;
    }

    if (reopened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RAT reaberta. Colete uma nova assinatura.'),
        ),
      );
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
            'Este RAT será removido da lista. Em modo empresa, a exclusão será sincronizada.',
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

  void _closeForm({bool? result}) async {
    if (!mounted) {
      return;
    }

    // If there are unsaved changes, ask for confirmation
    if (_hasUnsavedChanges) {
      final discard = await showTechReportDiscardDialog(context);
      if (!discard) return; // User cancelled, stay on screen
    }

    setState(() {
      _allowPop = true;
    });
    if (mounted) {
      Navigator.of(context).pop(result ?? widget.viewModel.shouldReloadOnClose);
    }
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

  Widget _buildSignatureSection(BuildContext context) {
    final viewModel = widget.viewModel;
    final theme = Theme.of(context);

    if (viewModel.isLoadingSignature) {
      return const LinearProgressIndicator();
    }

    final previewBytes = viewModel.signaturePreviewBytes;
    final isPending = viewModel.isSignaturePending;
    final hasValidSignature = viewModel.hasValidSignature;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isPending
                  ? Icons.pending_actions_outlined
                  : hasValidSignature
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: isPending
                  ? theme.colorScheme.tertiary
                  : hasValidSignature
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: MetricSlateSpacing.xs),
            Text(
              isPending
                  ? 'Assinatura pendente'
                  : hasValidSignature
                  ? 'Assinatura salva'
                  : 'Nenhuma assinatura salva',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        if (isPending) ...[
          const SizedBox(height: MetricSlateSpacing.xs),
          Text(
            'A assinatura anterior foi invalidada. Colete uma nova assinatura antes de finalizar o atendimento.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (previewBytes != null && !isPending) ...[
          const SizedBox(height: MetricSlateSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(MetricSlateRadii.sm),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MetricSlateRadii.sm),
              child: Padding(
                padding: const EdgeInsets.all(MetricSlateSpacing.sm),
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
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MetricSlateSpacing.md),
      child: TechReportCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TechReportSectionHeader(title: title, padding: EdgeInsets.zero),
            const SizedBox(height: MetricSlateSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HourTextInputFormatter extends TextInputFormatter {
  const _HourTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 4 ? digits.substring(0, 4) : digits;

    final text = switch (limitedDigits.length) {
      0 => '',
      <= 2 => limitedDigits,
      _ => '${limitedDigits.substring(0, 2)}:${limitedDigits.substring(2)}',
    };

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
