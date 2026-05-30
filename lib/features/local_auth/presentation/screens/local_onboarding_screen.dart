import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_section_header.dart';

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
        final scheme = Theme.of(context).colorScheme;
        final isLoading = widget.viewModel.isLoading;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                  child: TechReportCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TechReportFormHeader(
                            icon: Icons.person_add_outlined,
                            title: 'Primeiro acesso local',
                            subtitle:
                                'Configure o perfil do técnico neste dispositivo. '
                                'Nada aqui depende de backend nesta sprint.',
                          ),
                          const SizedBox(height: MetricSlateSpacing.lg),
                          const TechReportSectionHeader(
                            title: 'Perfil do técnico',
                            padding: EdgeInsets.zero,
                          ),
                          TextFormField(
                            controller: _nomeController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: MetricSlateSpacing.md),
                          TextFormField(
                            controller: _emailController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: MetricSlateSpacing.md),
                          TextFormField(
                            controller: _telefoneController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Telefone opcional',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: MetricSlateSpacing.md),
                          TextFormField(
                            controller: _empresaController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Empresa opcional',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                          ),
                          const SizedBox(height: MetricSlateSpacing.lg),
                          const TechReportSectionHeader(
                            title: 'Segurança',
                            subtitle:
                                'Nesta base local o PIN é opcional e fica fora do domínio.',
                            padding: EdgeInsets.zero,
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Proteger app com PIN'),
                            value: _usePin,
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _usePin = value;
                                    });
                                  },
                          ),
                          if (_usePin) ...[
                            const SizedBox(height: MetricSlateSpacing.sm),
                            TextFormField(
                              controller: _pinController,
                              enabled: !isLoading,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'PIN com 4 dígitos',
                                prefixIcon: Icon(Icons.pin_outlined),
                              ),
                            ),
                            const SizedBox(height: MetricSlateSpacing.md),
                            TextFormField(
                              controller: _pinConfirmationController,
                              enabled: !isLoading,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirmação do PIN',
                                prefixIcon: Icon(Icons.pin_outlined),
                              ),
                            ),
                          ],
                          if (widget.viewModel.errorMessage != null) ...[
                            const SizedBox(height: MetricSlateSpacing.md),
                            TechReportErrorBanner(
                              message: widget.viewModel.errorMessage!,
                            ),
                          ],
                          const SizedBox(height: MetricSlateSpacing.lg),
                          FilledButton.icon(
                            onPressed: isLoading ? null : _handleSubmit,
                            icon: isLoading
                                ? SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline, size: 20),
                            label: Text(
                              isLoading
                                  ? 'Salvando...'
                                  : 'Concluir onboarding',
                            ),
                          ),
                          if (widget.onBackToModeChoice != null) ...[
                            const SizedBox(height: MetricSlateSpacing.sm),
                            OutlinedButton(
                              onPressed: isLoading
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
