import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_spacing.dart';
import 'package:techreport/features/local_auth/domain/entities/tecnico_local.dart';
import 'package:techreport/features/local_auth/domain/repositories/tecnico_local_repository.dart';
import 'package:techreport/features/local_auth/domain/usecases/update_tecnico_local.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_card.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_error_banner.dart';
import 'package:techreport/shared/presentation/widgets/tech_report_form_header.dart';

/// Exposes the editing and loading state of [LocalProfileScreen] so that
/// a caller who supplies a custom [appBar] can react to those changes
/// (e.g. to show/hide an edit button in the injected AppBar).
class ProfileEditingNotifier extends ChangeNotifier {
  bool get isEditing => _isEditing;
  bool get isLoading => _isLoading;

  bool _isEditing = false;
  bool _isLoading = true;
  void Function()? _onStartEditing;

  void setEditing(bool value) {
    if (_isEditing == value) return;
    _isEditing = value;
    if (value && _onStartEditing != null) {
      _onStartEditing!();
    }
    notifyListeners();
  }

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  /// Registers a callback to be called when [setEditing] is invoked with
  /// `true`. Used by [_LocalProfileScreenState] to fill text controllers
  /// before entering edit mode.
  void setStartEditingCallback(void Function()? cb) {
    _onStartEditing = cb;
  }
}

class LocalProfileScreen extends StatefulWidget {
  const LocalProfileScreen({
    super.key,
    required this.appSessionViewModel,
    required this.tecnicoLocalRepository,
    this.appBar,
    this.editingNotifier,
  });

  final AppSessionViewModel appSessionViewModel;
  final TecnicoLocalRepository tecnicoLocalRepository;
  final PreferredSizeWidget? appBar;
  final ProfileEditingNotifier? editingNotifier;

  @override
  State<LocalProfileScreen> createState() => _LocalProfileScreenState();
}

class _LocalProfileScreenState extends State<LocalProfileScreen> {
  late final ProfileEditingNotifier _editingNotifier;

  TecnicoLocal? _tecnico;
  String? _errorMessage;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editingNotifier = widget.editingNotifier ?? ProfileEditingNotifier();
    _editingNotifier.setStartEditingCallback(_onNotifierStartEditing);
    _loadTecnico();
  }

  @override
  void dispose() {
    if (widget.editingNotifier == null) {
      _editingNotifier.dispose();
    }
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadTecnico() async {
    _editingNotifier.setLoading(true);
    _editingNotifier.setEditing(false);
    setState(() {
      _errorMessage = null;
    });

    try {
      final tecnico = await widget.tecnicoLocalRepository.getCurrent();
      setState(() {
        _tecnico = tecnico;
      });
      _editingNotifier.setLoading(false);
    } catch (_) {
      setState(() {
        _errorMessage = 'Não foi possível carregar o perfil.';
      });
      _editingNotifier.setLoading(false);
    }
  }

  void _startEditing() {
    _nomeController.text = _tecnico?.nome ?? '';
    _emailController.text = _tecnico?.email ?? '';
    _editingNotifier.setEditing(true);
  }

  void _cancelEditing() {
    _editingNotifier.setEditing(false);
  }

  void _onNotifierStartEditing() {
    _nomeController.text = _tecnico?.nome ?? '';
    _emailController.text = _tecnico?.email ?? '';
  }

  Future<void> _saveEditing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final update = UpdateTecnicoLocal(widget.tecnicoLocalRepository);
      await update.call(
        nome: _nomeController.text,
        email: _emailController.text,
      );
      await _loadTecnico();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
      }
    } catch (_) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Não foi possível salvar. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ListenableBuilder(
          listenable: _editingNotifier,
          builder: (context, _) {
            final provided = widget.appBar;
            if (provided != null) return provided;
            return AppBar(
              title: const Text('Meu perfil'),
              actions: [
                if (!_editingNotifier.isEditing && !_editingNotifier.isLoading)
                  IconButton(
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar perfil',
                  ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_editingNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _tecnico == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: MetricSlateSpacing.md),
            FilledButton(
              onPressed: _loadTecnico,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MetricSlateSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            TechReportErrorBanner(message: _errorMessage!),
            const SizedBox(height: MetricSlateSpacing.md),
          ],
          if (_editingNotifier.isEditing)
            _buildEditForm()
          else
            _buildReadOnlyProfile(),
        ],
      ),
    );
  }

  Widget _buildReadOnlyProfile() {
    final t = _tecnico;
    if (t == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileCard(icon: Icons.person_outline, title: 'Nome', value: t.nome),
        const SizedBox(height: MetricSlateSpacing.sm),
        ProfileCard(icon: Icons.mail_outline, title: 'E-mail', value: t.email),
        if (t.telefone != null && t.telefone!.isNotEmpty) ...[
          const SizedBox(height: MetricSlateSpacing.sm),
          ProfileCard(
            icon: Icons.phone_outlined,
            title: 'Telefone',
            value: t.telefone!,
          ),
        ],
        if (t.empresaNome != null && t.empresaNome!.isNotEmpty) ...[
          const SizedBox(height: MetricSlateSpacing.sm),
          ProfileCard(
            icon: Icons.business_outlined,
            title: 'Empresa',
            value: t.empresaNome!,
          ),
        ],
        const SizedBox(height: MetricSlateSpacing.sm),
        ProfileCard(
          icon: t.pinConfigured
              ? Icons.lock_outlined
              : Icons.lock_open_outlined,
          title: 'PIN',
          value: t.pinConfigured ? 'Configurado' : 'Não configurado',
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return TechReportCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TechReportFormHeader(
              icon: Icons.edit_outlined,
              title: 'Editar perfil',
              subtitle: 'Altere seus dados de identificação local.',
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            TextFormField(
              controller: _nomeController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o nome.' : null,
            ),
            const SizedBox(height: MetricSlateSpacing.md),
            TextFormField(
              controller: _emailController,
              enabled: !_isSaving,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o e-mail.';
                }
                if (!v.contains('@')) {
                  return 'Informe um e-mail válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: MetricSlateSpacing.lg),
            FilledButton(
              onPressed: _isSaving ? null : _saveEditing,
              child: Text(_isSaving ? 'Salvando...' : 'Salvar'),
            ),
            const SizedBox(height: MetricSlateSpacing.sm),
            OutlinedButton(
              onPressed: _isSaving ? null : _cancelEditing,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TechReportCard(
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: MetricSlateSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
