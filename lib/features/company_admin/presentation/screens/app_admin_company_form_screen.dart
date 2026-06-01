import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_empresa_resumo.dart';
import 'package:techreport/features/company_admin/presentation/view_models/app_admin_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';

class AppAdminCreateCompanyScreen extends StatefulWidget {
  const AppAdminCreateCompanyScreen({super.key, required this.viewModel});

  final AppAdminViewModel viewModel;

  @override
  State<AppAdminCreateCompanyScreen> createState() =>
      _AppAdminCreateCompanyScreenState();
}

class _AppAdminCreateCompanyScreenState
    extends State<AppAdminCreateCompanyScreen> {
  final _nomeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar empresa')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MetricSlateSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TechReportCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TechReportFormHeader(
                      icon: Icons.add_business_outlined,
                      title: 'Nova empresa',
                      subtitle: 'Cadastre a empresa antes de convidar admins.',
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: MetricSlateSpacing.md),
                      TechReportErrorBanner(message: _errorMessage!),
                    ],
                    const SizedBox(height: MetricSlateSpacing.lg),
                    TextField(
                      controller: _nomeController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Nome da empresa',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: MetricSlateSpacing.lg),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_outlined),
                      label: Text(_isSubmitting ? 'Criando...' : 'Criar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome da empresa.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.viewModel.createEmpresa(nome: nome);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage =
          widget.viewModel.errorMessage ?? 'Nao foi possivel criar a empresa.';
    });
  }
}

class AppAdminInviteCompanyAdminScreen extends StatefulWidget {
  const AppAdminInviteCompanyAdminScreen({
    super.key,
    required this.viewModel,
    required this.empresa,
  });

  final AppAdminViewModel viewModel;
  final AdminEmpresaResumo empresa;

  @override
  State<AppAdminInviteCompanyAdminScreen> createState() =>
      _AppAdminInviteCompanyAdminScreenState();
}

class _AppAdminInviteCompanyAdminScreenState
    extends State<AppAdminInviteCompanyAdminScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  CreateTecnicoConviteResult? _result;

  String get _email => _emailController.text.trim();

  String get _inviteLink {
    final code = _result?.codigoConvite ?? '';
    return 'techreport://convite?codigo=${Uri.encodeComponent(code)}';
  }

  String get _shareText {
    final result = _result;
    if (result == null) return '';

    return 'Voce recebeu um convite para administrar ${widget.empresa.nome} no TechReport.\n\n'
        'E-mail: $_email\n'
        'Codigo: ${result.codigoConvite}\n'
        'Link: $_inviteLink\n\n'
        'Abra o app, escolha "Aceitar convite" e crie sua senha.';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: Text(result == null ? 'Convidar admin' : 'Convite criado'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MetricSlateSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: result == null ? _buildForm() : _buildSuccess(result),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return TechReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TechReportFormHeader(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin da empresa',
            subtitle: widget.empresa.nome,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: MetricSlateSpacing.md),
            TechReportErrorBanner(message: _errorMessage!),
          ],
          const SizedBox(height: MetricSlateSpacing.lg),
          TextField(
            controller: _nomeController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: MetricSlateSpacing.md),
          TextField(
            controller: _emailController,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: MetricSlateSpacing.lg),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mark_email_unread_outlined),
            label: Text(_isSubmitting ? 'Gerando...' : 'Gerar convite'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(CreateTecnicoConviteResult result) {
    return TechReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TechReportFormHeader(
            icon: Icons.check_circle_outline,
            title: 'Convite pronto',
            subtitle: 'Envie o link ou codigo para o admin.',
          ),
          const SizedBox(height: MetricSlateSpacing.lg),
          SelectableText(
            result.codigoConvite,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: MetricSlateSpacing.sm),
          SelectableText(_inviteLink, textAlign: TextAlign.center),
          const SizedBox(height: MetricSlateSpacing.lg),
          FilledButton.icon(
            onPressed: () => _copy(result.codigoConvite, 'Codigo copiado.'),
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copiar codigo'),
          ),
          const SizedBox(height: MetricSlateSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _copy(_inviteLink, 'Link copiado.'),
            icon: const Icon(Icons.link_outlined),
            label: const Text('Copiar link'),
          ),
          const SizedBox(height: MetricSlateSpacing.sm),
          OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Compartilhar convite'),
          ),
          const SizedBox(height: MetricSlateSpacing.lg),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Voltar para empresas'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();

    if (nome.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome.');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Informe um e-mail valido.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await widget.viewModel.inviteAdminEmpresa(
      empresa: widget.empresa,
      nome: nome,
      email: email,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _result = result;
      _errorMessage = result == null
          ? widget.viewModel.errorMessage ?? 'Nao foi possivel gerar o convite.'
          : null;
    });
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _share() {
    return SharePlus.instance.share(
      ShareParams(subject: 'Convite para o TechReport', text: _shareText),
    );
  }
}
