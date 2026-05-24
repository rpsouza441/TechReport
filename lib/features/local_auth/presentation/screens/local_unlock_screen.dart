import 'package:flutter/material.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';

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
        final theme = Theme.of(context);

        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desbloquear modo local',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A sessão local existe, mas o app voltou bloqueado porque '
                        'o PIN foi configurado.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'PIN'),
                        onSubmitted: (_) => _submit(),
                      ),
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
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _submit,
                        child: const Text('Desbloquear'),
                      ),
                    ],
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
