import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/presentation/view_models/company_accept_invite_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';

class CompanyAcceptInviteScreen extends StatefulWidget {
  const CompanyAcceptInviteScreen({
    super.key,
    required this.viewModel,
    required this.onAccepted,
    this.onCancel,
  });

  final CompanyAcceptInviteViewModel viewModel;
  final ValueChanged<SessaoRemota> onAccepted;
  final VoidCallback? onCancel;

  @override
  State<CompanyAcceptInviteScreen> createState() =>
      _CompanyAcceptInviteScreenState();
}

class _CompanyAcceptInviteScreenState extends State<CompanyAcceptInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codigoController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final isSubmitting = widget.viewModel.isSubmitting;

        return Scaffold(
          appBar: AppBar(title: const Text('Aceitar convite')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: TechReportCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TechReportFormHeader(
                            icon: Icons.mail_lock_outlined,
                            title: 'Entrar com convite',
                            subtitle:
                                'Use o e-mail convidado, sua senha e o código '
                                'informado pelo admin da empresa.',
                          ),
                          if (widget.viewModel.errorMessage != null) ...[
                            TechReportErrorBanner(
                              message: widget.viewModel.errorMessage!,
                            ),
                            const SizedBox(height: MetricSlateSpacing.md),
                          ],
                          TextFormField(
                            controller: _emailController,
                            enabled: !isSubmitting,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail convidado',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: MetricSlateSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !isSubmitting,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: MetricSlateSpacing.md),
                          TextFormField(
                            controller: _codigoController,
                            enabled: !isSubmitting,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Código do convite',
                              prefixIcon: Icon(Icons.vpn_key_outlined),
                            ),
                            validator: _validateCode,
                          ),
                          const SizedBox(height: MetricSlateSpacing.lg),
                          FilledButton(
                            onPressed: isSubmitting ? null : _submit,
                            child: isSubmitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Aceitar e entrar'),
                          ),
                          if (widget.onCancel != null) ...[
                            const SizedBox(height: MetricSlateSpacing.sm),
                            OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : widget.onCancel,
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

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Informe o e-mail.';
    }
    if (!email.contains('@')) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha.';
    }
    return null;
  }

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o código do convite.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.viewModel.submit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      codigoConvite: _codigoController.text.trim(),
    );

    if (!mounted || !success || widget.viewModel.session == null) {
      return;
    }

    widget.onAccepted(widget.viewModel.session!);
  }
}
