import '../entities/sessao_local.dart';
import '../repositories/sessao_local_repository.dart';

class LockLocalSession {
  LockLocalSession(this._repository);

  final SessaoLocalRepository _repository;

  Future<SessaoLocal?> call() async {
    final current = await _repository.getCurrentSession();
    if (current == null || !current.pinConfigured) {
      return current;
    }

    final locked = current.copyWith(
      status: SessaoLocalStatus.locked,
      updatedAt: DateTime.now(),
    );
    await _repository.saveSession(locked);
    return locked;
  }
}
