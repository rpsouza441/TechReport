import 'package:techreport/features/local_auth/domain/repositories/pin_secret_repository.dart';

import '../entities/sessao_local.dart';
import '../repositories/sessao_local_repository.dart';

class UnlockLocalSessionResult {
  const UnlockLocalSessionResult({
    required this.session,
    required this.success,
  });

  final SessaoLocal? session;
  final bool success;
}

class UnlockLocalSession {
  UnlockLocalSession(
    this._repository, {
    required PinSecretRepository pinSecretRepository,
  }) : _pinSecretRepository = pinSecretRepository;

  final SessaoLocalRepository _repository;
  final PinSecretRepository _pinSecretRepository;

  Future<UnlockLocalSessionResult> call(String pin) async {
    final current = await _repository.getCurrentSession();

    if (current == null) {
      return const UnlockLocalSessionResult(session: null, success: false);
    }

    if (!current.pinConfigured) {
      return UnlockLocalSessionResult(session: current, success: true);
    }

    final isValid = await _pinSecretRepository.verifyPin(pin);
    if (!isValid) {
      return UnlockLocalSessionResult(session: current, success: false);
    }

    final unlocked = current.copyWith(
      status: SessaoLocalStatus.unlocked,
      lastUnlockedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.saveSession(unlocked);
    return UnlockLocalSessionResult(session: unlocked, success: true);
  }
}
