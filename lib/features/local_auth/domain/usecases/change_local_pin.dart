import '../entities/sessao_local.dart';
import '../repositories/pin_secret_repository.dart';
import '../repositories/sessao_local_repository.dart';
import '../repositories/tecnico_local_repository.dart';

enum ChangeLocalPinFailure {
  invalidCurrentPin,
  invalidNewPin,
  confirmationMismatch,
  missingSession,
}

class ChangeLocalPinResult {
  const ChangeLocalPinResult._({
    required this.success,
    this.session,
    this.failure,
  });

  const ChangeLocalPinResult.success(SessaoLocal session)
    : this._(success: true, session: session);

  const ChangeLocalPinResult.failure(ChangeLocalPinFailure failure)
    : this._(success: false, failure: failure);

  final bool success;
  final SessaoLocal? session;
  final ChangeLocalPinFailure? failure;
}

class ChangeLocalPin {
  ChangeLocalPin({
    required PinSecretRepository pinSecretRepository,
    required SessaoLocalRepository sessaoLocalRepository,
    required TecnicoLocalRepository tecnicoLocalRepository,
  }) : _pinSecretRepository = pinSecretRepository,
       _sessaoLocalRepository = sessaoLocalRepository,
       _tecnicoLocalRepository = tecnicoLocalRepository;

  final PinSecretRepository _pinSecretRepository;
  final SessaoLocalRepository _sessaoLocalRepository;
  final TecnicoLocalRepository _tecnicoLocalRepository;

  Future<ChangeLocalPinResult> call({
    String? currentPin,
    required String newPin,
    required String confirmation,
  }) async {
    final trimmedCurrentPin = currentPin?.trim() ?? '';
    final trimmedNewPin = newPin.trim();
    final trimmedConfirmation = confirmation.trim();
    final session = await _sessaoLocalRepository.getCurrentSession();

    if (session == null || session.requiresOnboarding) {
      return const ChangeLocalPinResult.failure(
        ChangeLocalPinFailure.missingSession,
      );
    }

    if (session.pinConfigured) {
      final currentIsValid = await _pinSecretRepository.verifyPin(
        trimmedCurrentPin,
      );
      if (!currentIsValid) {
        return const ChangeLocalPinResult.failure(
          ChangeLocalPinFailure.invalidCurrentPin,
        );
      }
    }

    if (trimmedNewPin.length != 4) {
      return const ChangeLocalPinResult.failure(
        ChangeLocalPinFailure.invalidNewPin,
      );
    }

    if (trimmedNewPin != trimmedConfirmation) {
      return const ChangeLocalPinResult.failure(
        ChangeLocalPinFailure.confirmationMismatch,
      );
    }

    await _pinSecretRepository.savePin(trimmedNewPin);

    final now = DateTime.now();
    final updatedSession = session.copyWith(
      pinConfigured: true,
      status: SessaoLocalStatus.unlocked,
      lastUnlockedAt: now,
      updatedAt: now,
    );
    await _sessaoLocalRepository.saveSession(updatedSession);

    final tecnico = await _tecnicoLocalRepository.getCurrent();
    if (tecnico != null) {
      await _tecnicoLocalRepository.save(
        tecnico.copyWith(pinConfigured: true, updatedAt: now),
      );
    }

    return ChangeLocalPinResult.success(updatedSession);
  }
}
