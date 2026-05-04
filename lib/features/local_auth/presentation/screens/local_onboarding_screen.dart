import 'package:flutter/material.dart';

import '../view_models/app_session_view_model.dart';

class LocalOnboardingScreen extends StatefulWidget {
  const LocalOnboardingScreen({
    super.key,
    required this.viewModel,
    this.onBackToModeChoice,
  });

  final AppSessionViewModel viewModel;
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
                          'Configure o perfil do tecnico neste dispositivo. '
                          'Nada aqui depende de backend nesta sprint.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(labelText: 'Nome'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
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
                            'Nesta base local o PIN e opcional e fica fora do dominio.',
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
                              labelText: 'PIN com 4 digitos',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pinConfirmationController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmacao do PIN',
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
                          child: const Text('Concluir onboarding'),
                        ),
                        if (widget.onBackToModeChoice != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: widget.viewModel.isLoading
                                ? null
                                : widget.onBackToModeChoice,
                            child: const Text('Voltar para escolha de modo'),
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
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.viewModel.submitOnboarding(
      nome: _nomeController.text,
      email: _emailController.text,
      telefone: _telefoneController.text,
      empresaNome: _empresaController.text,
      usePin: _usePin,
      pin: _pinController.text,
      pinConfirmation: _pinConfirmationController.text,
    );
  }
}
