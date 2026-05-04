import 'package:flutter/material.dart';
import 'package:techreport/features/company_auth/presentation/view_models/remote_server_config_view_model.dart';

class RemoteServerConfigScreen extends StatefulWidget {
  const RemoteServerConfigScreen({
    super.key,
    required this.viewModel,
    this.onSaved,
    this.onCancel,
  });

  final RemoteServerConfigViewModel viewModel;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  @override
  State<RemoteServerConfigScreen> createState() =>
      _RemoteServerConfigScreenState();
}

class _RemoteServerConfigScreenState extends State<RemoteServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _urlController = TextEditingController();
  final _publicKeyController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _urlController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Configurar servidor')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Conectar ao servidor',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Informe a URL do Supabase e a chave publica enviada pela empresa.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (widget.viewModel.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.viewModel.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do servidor',
                            hintText: 'Empresa ou ambiente',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'URL do Supabase',
                            hintText: 'https://seu-projeto.supabase.co',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          validator: _validateUrl,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _publicKeyController,
                          decoration: const InputDecoration(
                            labelText: 'Anon/public key',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.done,
                          validator: _validatePublicKey,
                          onFieldSubmitted: (_) => _save(),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: widget.viewModel.isSaving ? null : _save,
                          child: widget.viewModel.isSaving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Salvar servidor'),
                        ),
                        if (widget.onCancel != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: widget.viewModel.isSaving
                                ? null
                                : widget.onCancel,
                            child: const Text('Voltar'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            ),
          ),
        );
      },
    );
  }

  String? _validateUrl(String? value) {
    final rawUrl = value?.trim() ?? '';
    final uri = Uri.tryParse(rawUrl);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Informe uma URL valida.';
    }

    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return 'Use uma URL iniciada com http ou https.';
    }

    return null;
  }

  String? _validatePublicKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe a anon/public key.';
    }

    return null;
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || widget.viewModel.isSaving) {
      return;
    }

    final success = await widget.viewModel.save(
      nome: _nomeController.text,
      supabaseUrl: _urlController.text,
      supabasePublicKey: _publicKeyController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servidor salvo com sucesso.')),
      );
      widget.onSaved?.call();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.viewModel.errorMessage ?? 'Nao foi possivel salvar servidor.',
        ),
      ),
    );
  }
}
