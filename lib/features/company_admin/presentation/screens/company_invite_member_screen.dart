import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_convite_resumo.dart';
import 'package:techreport/features/company_admin/domain/entities/admin_tecnico_resumo.dart';
import 'package:techreport/features/company_admin/presentation/view_models/admin_empresa_view_model.dart';
import 'package:techreport/shared/presentation/widgets/metric_slate_text_field.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';

class CompanyInviteMemberScreen extends StatefulWidget {
  const CompanyInviteMemberScreen({super.key, required this.viewModel});

  final AdminEmpresaViewModel viewModel;

  @override
  State<CompanyInviteMemberScreen> createState() =>
      _CompanyInviteMemberScreenState();
}

class _CompanyInviteMemberScreenState extends State<CompanyInviteMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  AdminTecnicoPapel _papel = AdminTecnicoPapel.tecnico;
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

    return 'Voce recebeu um convite para acessar o TechReport.\n\n'
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
        title: Text(result == null ? 'Novo convite' : 'Convite criado'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MetricSlateSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: result == null ? _buildForm(context) : _buildSuccess(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: TechReportCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TechReportFormHeader(
              icon: Icons.person_add_outlined,
              title: 'Convidar membro',
              subtitle:
                  'O convidado vai criar a conta pelo app usando o codigo.',
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: MetricSlateSpacing.md),
              TechReportErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: MetricSlateSpacing.lg),
            MetricSlateTextField(controller: _nomeController, label: 'Nome'),
            const SizedBox(height: MetricSlateSpacing.md),
            MetricSlateTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              label: 'E-mail',
            ),
            const SizedBox(height: MetricSlateSpacing.md),
            DropdownButtonFormField<AdminTecnicoPapel>(
              initialValue: _papel,
              decoration: const InputDecoration(labelText: 'Papel'),
              items: const [
                DropdownMenuItem(
                  value: AdminTecnicoPapel.adminEmpresa,
                  child: Text('Admin da empresa'),
                ),
                DropdownMenuItem(
                  value: AdminTecnicoPapel.gerente,
                  child: Text('Gerente'),
                ),
                DropdownMenuItem(
                  value: AdminTecnicoPapel.tecnico,
                  child: Text('Tecnico'),
                ),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _papel = value);
                      }
                    },
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
      ),
    );
  }

  Widget _buildSuccess() {
    final result = _result!;

    return TechReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TechReportFormHeader(
            icon: Icons.check_circle_outline,
            title: 'Convite pronto',
            subtitle: 'Envie o link ou codigo para o convidado.',
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
            child: const Text('Voltar para equipe'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();

    if (nome.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome do convidado.');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Informe um e-mail valido.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.viewModel.createConvite(
        email: email,
        nome: nome,
        papel: _papel,
      );
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _inviteErrorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

  String _inviteErrorMessage(Object error) {
    final message = error.toString();
    const prefix = 'PostgrestException(message: ';
    if (message.contains(prefix)) {
      final start = message.indexOf(prefix) + prefix.length;
      final end = message.indexOf(',', start);
      if (end > start) {
        return message.substring(start, end);
      }
    }

    if (message.contains('Could not find the function')) {
      return 'Fluxo de convites indisponivel. Aplique as migrations 0009 a 0011.';
    }

    return 'Nao foi possivel gerar o convite.';
  }
}
