import '../entities/sessao_local.dart';
import '../repositories/pin_secret_repository.dart';
import '../repositories/sessao_local_repository.dart';

class BootstrapLocalSession {
  BootstrapLocalSession(
    this._repository, {
    required PinSecretRepository pinSecretRepository,
  }) : _pinSecretRepository = pinSecretRepository;

  final SessaoLocalRepository _repository;
  final PinSecretRepository _pinSecretRepository;

  Future<SessaoLocal?> call() async {
    final session = await _repository.getCurrentSession();
    if (session == null) return null;

    final normalized = session.copyWith(
      status: SessaoLocalStatus.unlocked,
      pinConfigured: false,
      biometriaHabilitada: false,
    );
    if (normalized != session) {
      await _repository.saveSession(normalized);
    }

    try {
      await _pinSecretRepository.deletePin();
    } catch (_) {
      // A limpeza do PIN legado nao pode bloquear dados locais ja abertos.
    }

    return normalized;
  }
}
