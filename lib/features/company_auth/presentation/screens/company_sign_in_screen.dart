import 'package:flutter/material.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/presentation/view_models/company_sign_in_view_model.dart';

class CompanySignInScreen extends StatefulWidget {
  const CompanySignInScreen({
    super.key,
    required this.viewModel,
    required this.onSignedIn,
    this.onCancel,
  });

  final CompanySignInViewModel viewModel;
  final ValueChanged<SessaoRemota> onSignedIn;
  final VoidCallback? onCancel;

  @override
  State<CompanySignInScreen> createState() => _CompanySignInScreenState();
}

class _CompanySignInScreenState extends State<CompanySignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Entrar na empresa')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Login empresa',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Use o email e senha da conta remota.',
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
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: widget.viewModel.isSubmitting
                              ? null
                              : _submit,
                          child: widget.viewModel.isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                        if (widget.onCancel != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: widget.viewModel.isSubmitting
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
        );
      },
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o email.';
    }

    if (!email.contains('@')) {
      return 'Informe um email valido.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe a senha.';
    }

    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || widget.viewModel.isSubmitting) {
      return;
    }

    final success = await widget.viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || !success || widget.viewModel.session == null) {
      return;
    }

    widget.onSignedIn(widget.viewModel.session!);
  }
}
