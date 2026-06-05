import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';

class LocalUnlockScreen extends StatefulWidget {
  const LocalUnlockScreen({
    super.key,
    required this.viewModel,
    required this.onUnlocked,
  });

  final AppSessionViewModel viewModel;
  final VoidCallback onUnlocked;

  @override
  State<LocalUnlockScreen> createState() => _LocalUnlockScreenState();
}

class _LocalUnlockScreenState extends State<LocalUnlockScreen> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: TechReportCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TechReportFormHeader(
                          icon: Icons.lock_outline,
                          title: 'Desbloquear modo local',
                          subtitle:
                              'A sessão local existe, mas o app voltou bloqueado porque o PIN foi configurado.',
                        ),
                        const SizedBox(height: MetricSlateSpacing.lg),
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 8,
                          decoration: const InputDecoration(
                            labelText: 'PIN',
                            prefixIcon: Icon(Icons.pin_outlined),
                            counterText: '',
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (widget.viewModel.errorMessage != null) ...[
                          const SizedBox(height: MetricSlateSpacing.md),
                          TechReportErrorBanner(
                            message: widget.viewModel.errorMessage!,
                          ),
                        ],
                        const SizedBox(height: MetricSlateSpacing.lg),
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.lock_open_outlined, size: 20),
                          label: const Text('Desbloquear'),
                        ),
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

  Future<void> _submit() async {
    await widget.viewModel.unlock(_pinController.text);

    if (widget.viewModel.status == AppSessionStatus.unlocked) {
      widget.onUnlocked();
    }
  }
}
