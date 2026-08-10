import 'package:flutter/foundation.dart';

import '../../domain/entities/sessao_local.dart';
import '../../domain/usecases/bootstrap_local_session.dart';
import '../../domain/usecases/complete_local_onboarding.dart';

enum AppSessionStatus { onboardingRequired, ready }

class AppSessionViewModel extends ChangeNotifier {
  AppSessionViewModel({
    required BootstrapLocalSession bootstrapLocalSession,
    required CompleteLocalOnboarding completeLocalOnboarding,
  }) : _bootstrapLocalSession = bootstrapLocalSession,
       _completeLocalOnboarding = completeLocalOnboarding;

  final BootstrapLocalSession _bootstrapLocalSession;
  final CompleteLocalOnboarding _completeLocalOnboarding;

  bool _isLoading = true;
  String? _errorMessage;
  SessaoLocal? _session;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AppSessionStatus get status {
    final session = _session;
    if (session == null || session.requiresOnboarding) {
      return AppSessionStatus.onboardingRequired;
    }
    return AppSessionStatus.ready;
  }

  Future<void> bootstrap() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _session = await _bootstrapLocalSession();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitOnboarding({
    required String nome,
    required String email,
    String? telefone,
    String? empresaNome,
  }) async {
    _errorMessage = _validateOnboarding(nome: nome, email: email);
    if (_errorMessage != null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    _session = await _completeLocalOnboarding(
      CompleteLocalOnboardingInput(
        nome: nome,
        email: email,
        telefone: telefone,
        empresaNome: empresaNome,
      ),
    );
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  String? _validateOnboarding({required String nome, required String email}) {
    if (nome.trim().isEmpty) return 'Informe o nome do técnico.';
    if (email.trim().isEmpty || !email.contains('@')) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }
}
