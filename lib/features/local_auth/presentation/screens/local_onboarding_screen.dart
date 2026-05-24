import 'package:flutter/material.dart';

import '../view_models/app_session_view_model.dart';

class LocalOnboardingScreen extends StatefulWidget {
  const LocalOnboardingScreen({
    super.key,
    required this.viewModel,
    required this.onCompleted,
    this.onBackToModeChoice,
  });

  final AppSessionViewModel viewModel;
  final VoidCallback onCompleted;
  final Future<void> Function()? onBackToModeChoice;

  @override
  State<LocalOnboardingScreen> createState() => _LocalOnboardingScreenState();
}

class _LocalOnboardingScreenState extends State<LocalOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _empresaController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmationController = TextEditingController();
  bool _usePin = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _empresaController.dispose();
    _pinController.dispose();
    _pinConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final theme = Theme.of(context);

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Primeiro acesso local',
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Configure o perfil do técnico neste dispositivo. '
                              'Nada aqui depende de backend nesta sprint.',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _telefoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefone opcional',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _empresaController,
                              decoration: const InputDecoration(
                                labelText: 'Empresa opcional',
                              ),
                            ),
                            const SizedBox(height: 24),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Proteger app com PIN'),
                              subtitle: const Text(
                                'Nesta base local o PIN é opcional e fica fora do domínio.',
                              ),
                              value: _usePin,
                              onChanged: (value) {
                                setState(() {
                                  _usePin = value;
                                });
                              },
                            ),
                            if (_usePin) ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _pinController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'PIN com 4 dígitos',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _pinConfirmationController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Confirmação do PIN',
                                ),
                              ),
                            ],
                            if (widget.viewModel.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                widget.viewModel.errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: widget.viewModel.isLoading
                                  ? null
                                  : _handleSubmit,
                              child: widget.viewModel.isLoading
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Concluir onboarding'),
                            ),
                            if (widget.onBackToModeChoice != null) ...[
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: widget.viewModel.isLoading
                                    ? null
                                    : widget.onBackToModeChoice,
                                child: const Text(
                                  'Voltar para escolha de modo',
                                ),
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
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.viewModel.submitOnboarding(
      nome: _nomeController.text,
      email: _emailController.text,
      telefone: _telefoneController.text,
      empresaNome: _empresaController.text,
      usePin: _usePin,
      pin: _pinController.text,
      pinConfirmation: _pinConfirmationController.text,
    );

    if (!mounted || widget.viewModel.status != AppSessionStatus.unlocked) {
      return;
    }

    widget.onCompleted();
  }
}
