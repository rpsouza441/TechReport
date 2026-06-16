import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_discard_dialog.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';

/// Tela de edição do nome exibido no perfil do usuário.
/// Não usa popup, dialog ou bottom sheet.
class CompanyEditProfileScreen extends StatefulWidget {
  const CompanyEditProfileScreen({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  final String? initialName;
  final Future<bool> Function(String name) onSave;

  @override
  State<CompanyEditProfileScreen> createState() =>
      _CompanyEditProfileScreenState();
}

class _CompanyEditProfileScreenState extends State<CompanyEditProfileScreen> {
  late final TextEditingController _nameController;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _nameController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final current = _nameController.text.trim();
    final initial = widget.initialName?.trim() ?? '';
    if (current != initial) {
      if (!_hasChanges) setState(() => _hasChanges = true);
    } else {
      if (_hasChanges) setState(() => _hasChanges = false);
    }
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final ok = await widget.onSave(trimmed);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nome atualizado.')));
        Navigator.of(context).pop(trimmed);
      } else {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Não foi possível salvar. Tente novamente.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Não foi possível salvar. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await showTechReportDiscardDialog(context);
        if (discard && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MetricSlateSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TechReportFormHeader(
                      icon: Icons.person_outlined,
                      title: 'Nome exibido',
                      subtitle: 'Este nome aparece nos RATs criados por você.',
                    ),
                    const SizedBox(height: MetricSlateSpacing.md),
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _hasChanges ? _handleSave() : null,
                      decoration: InputDecoration(
                        hintText: 'Digite seu nome',
                        errorText: _errorMessage,
                      ),
                    ),
                    const SizedBox(height: MetricSlateSpacing.xl),
                    FilledButton(
                      onPressed: (_isSaving || !_hasChanges)
                          ? null
                          : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar alterações'),
                    ),
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
