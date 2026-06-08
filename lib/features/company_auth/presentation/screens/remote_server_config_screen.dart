import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_auth/presentation/view_models/remote_server_config_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';

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
  final _urlController = TextEditingController();
  final _publicKeyController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final isSaving = widget.viewModel.isSaving;

        return Scaffold(
          appBar: AppBar(title: const Text('Configurar servidor')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: TechReportCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TechReportFormHeader(
                            icon: Icons.dns_outlined,
                            title: 'Conectar ao servidor',
                            subtitle:
                                'Informe a URL do Supabase e a chave pública enviada pela empresa.',
                          ),
                          if (widget.viewModel.errorMessage != null) ...[
                            const SizedBox(height: MetricSlateSpacing.md),
                            TechReportErrorBanner(
                              message: widget.viewModel.errorMessage!,
                            ),
                          ],
                          const SizedBox(height: MetricSlateSpacing.lg),
                          TextFormField(
                            controller: _urlController,
                            enabled: !isSaving,
                            decoration: const InputDecoration(
                              labelText: 'URL do Supabase',
                              hintText: 'https://seu-projeto.supabase.co',
                              prefixIcon: Icon(Icons.link_outlined),
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            validator: _validateUrl,
                          ),
                          const SizedBox(height: MetricSlateSpacing.md),
                          TextFormField(
                            controller: _publicKeyController,
                            enabled: !isSaving,
                            decoration: const InputDecoration(
                              labelText: 'Anon/public key',
                              prefixIcon: Icon(Icons.vpn_key_outlined),
                            ),
                            textInputAction: TextInputAction.done,
                            validator: _validatePublicKey,
                            onFieldSubmitted: (_) => _save(),
                          ),
                          const SizedBox(height: MetricSlateSpacing.lg),
                          FilledButton.icon(
                            onPressed: isSaving ? null : _save,
                            icon: isSaving
                                ? SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined, size: 20),
                            label: Text(
                              isSaving ? 'Salvando...' : 'Salvar servidor',
                            ),
                          ),
                          if (widget.onCancel != null) ...[
                            const SizedBox(height: MetricSlateSpacing.sm),
                            OutlinedButton(
                              onPressed: isSaving ? null : widget.onCancel,
                              child: const Text('Voltar'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
      return 'Informe uma URL válida.';
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
      nome: '',
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
          widget.viewModel.errorMessage ??
              'Não foi possível salvar servidor.',
        ),
      ),
    );
  }
}
