import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/presentation/view_models/company_sign_in_view_model.dart';
import 'package:techreport/shared/presentation/widgets/hierarchical_background.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';

class CompanySignInScreen extends StatefulWidget {
  const CompanySignInScreen({
    super.key,
    required this.viewModel,
    required this.onSignedIn,
    this.onCancel,
    this.onAcceptInvite,
    this.onChangeServer,
  });

  final CompanySignInViewModel viewModel;
  final ValueChanged<SessaoRemota> onSignedIn;
  final VoidCallback? onCancel;
  final VoidCallback? onAcceptInvite;
  final VoidCallback? onChangeServer;

  @override
  State<CompanySignInScreen> createState() => _CompanySignInScreenState();
}

class _CompanySignInScreenState extends State<CompanySignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final isSubmitting = widget.viewModel.isSubmitting;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: HierarchicalBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(MetricSlateSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BrandHeader(theme: theme, scheme: scheme),
                        const SizedBox(height: MetricSlateSpacing.xl),
                        TechReportCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.viewModel.errorMessage != null) ...[
                                  const SizedBox(height: MetricSlateSpacing.md),
                                  TechReportCard(
                                    tone: TechReportCardTone.error,
                                    padding: const EdgeInsets.all(
                                      MetricSlateSpacing.sm,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          size: 22,
                                        ),
                                        const SizedBox(
                                          width: MetricSlateSpacing.sm,
                                        ),
                                        Expanded(
                                          child: Text(
                                            widget.viewModel.errorMessage!,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: MetricSlateSpacing.lg),
                                TextFormField(
                                  controller: _emailController,
                                  enabled: !isSubmitting,
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail corporativo',
                                    hintText: 'usuario@empresa.com.br',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
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
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  validator: _validatePassword,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: MetricSlateSpacing.lg),
                                FilledButton.icon(
                                  onPressed: isSubmitting ? null : _submit,
                                  icon: isSubmitting
                                      ? SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: scheme.onPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.login, size: 20),
                                  label: Text(
                                    isSubmitting ? 'Entrando...' : 'Entrar',
                                  ),
                                ),
                                if (widget.onCancel != null) ...[
                                  const SizedBox(height: MetricSlateSpacing.sm),
                                  OutlinedButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : _confirmExitCompanyMode,
                                    child: const Text('Sair do modo empresa'),
                                  ),
                                ],
                                if (widget.onChangeServer != null) ...[
                                  const SizedBox(height: MetricSlateSpacing.xs),
                                  TextButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : _confirmChangeServer,
                                    child: const Text('Trocar servidor'),
                                  ),
                                ],
                                if (widget.onAcceptInvite != null) ...[
                                  const SizedBox(height: MetricSlateSpacing.sm),
                                  TextButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : widget.onAcceptInvite,
                                    child: const Text(
                                      'Aceitar convite da empresa',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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

  Future<void> _confirmExitCompanyMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do modo empresa?'),
        content: const Text(
          'Você voltará para a escolha de modo. '
          'O servidor configurado continuará salvo neste dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onCancel?.call();
    }
  }

  Future<void> _confirmChangeServer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trocar servidor?'),
        content: const Text(
          'Você poderá informar uma nova URL e anon key. '
          'O servidor atual só será substituído depois que o novo '
          'servidor for salvo com sucesso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Trocar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onChangeServer?.call();
    }
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.theme, required this.scheme});

  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics_outlined, size: 32, color: scheme.primary),
            const SizedBox(width: MetricSlateSpacing.xs),
            Text(
              'TechReport',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: MetricSlateSpacing.xxs),
        Text('Acesso corporativo', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}