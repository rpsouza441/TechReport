import 'package:flutter/foundation.dart';

import '../../domain/entities/sessao_local.dart';
import '../../domain/usecases/bootstrap_local_session.dart';
import '../../domain/usecases/complete_local_onboarding.dart';
import '../../domain/usecases/lock_local_session.dart';
import '../../domain/usecases/unlock_local_session.dart';

enum AppSessionStatus {
  onboardingRequired,
  locked,
  unlocked,
}

class AppSessionViewModel extends ChangeNotifier {
  AppSessionViewModel({
    required BootstrapLocalSession bootstrapLocalSession,
    required CompleteLocalOnboarding completeLocalOnboarding,
    required LockLocalSession lockLocalSession,
    required UnlockLocalSession unlockLocalSession,
  })  : _bootstrapLocalSession = bootstrapLocalSession,
        _completeLocalOnboarding = completeLocalOnboarding,
        _lockLocalSession = lockLocalSession,
        _unlockLocalSession = unlockLocalSession;

  final BootstrapLocalSession _bootstrapLocalSession;
  final CompleteLocalOnboarding _completeLocalOnboarding;
  final LockLocalSession _lockLocalSession;
  final UnlockLocalSession _unlockLocalSession;

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

    if (session.isLocked) {
      return AppSessionStatus.locked;
    }

    return AppSessionStatus.unlocked;
  }

  bool get pinConfigured => _session?.pinConfigured ?? false;

  Future<void> bootstrap() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final session = await _bootstrapLocalSession();
    _session = session;

    if (session != null && session.pinConfigured && session.isUnlocked) {
      _session = await _lockLocalSession();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitOnboarding({
    required String nome,
    required String email,
    String? telefone,
    String? empresaNome,
    required bool usePin,
    String? pin,
    String? pinConfirmation,
  }) async {
    _errorMessage = _validateOnboarding(
      nome: nome,
      email: email,
      usePin: usePin,
      pin: pin,
      pinConfirmation: pinConfirmation,
    );

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
        usePin: usePin,
        pin: pin,
      ),
    );

    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> unlock(String pin) async {
    _errorMessage = null;

    final result = await _unlockLocalSession(pin);
    if (!result.success) {
      _errorMessage = 'PIN invalido. Use 4 digitos para desbloquear.';
      notifyListeners();
      return;
    }

    _session = result.session;
    notifyListeners();
  }

  Future<void> lock() async {
    _session = await _lockLocalSession();
    notifyListeners();
  }

  String? _validateOnboarding({
    required String nome,
    required String email,
    required bool usePin,
    String? pin,
    String? pinConfirmation,
  }) {
    if (nome.trim().isEmpty) {
      return 'Informe o nome do tecnico.';
    }

    if (email.trim().isEmpty || !email.contains('@')) {
      return 'Informe um email valido.';
    }

    if (!usePin) {
      return null;
    }

    if ((pin ?? '').trim().length != 4) {
      return 'Defina um PIN com 4 digitos.';
    }

    if (pin != pinConfirmation) {
      return 'A confirmacao do PIN nao confere.';
    }

    return null;
  }
}
