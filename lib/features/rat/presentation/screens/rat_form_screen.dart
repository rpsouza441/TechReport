import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _clienteController = TextEditingController(
      text: widget.viewModel.clienteNome,
    );
    _descricaoController = TextEditingController(
      text: widget.viewModel.descricao,
    );
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
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.viewModel.isEditing ? 'Editar RAT' : 'Novo RAT'),
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
                      labelText: 'Descricao',
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.viewModel.isSubmitting
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
      Navigator.of(context).pop(true);
    }
  }
}
