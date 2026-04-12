import '../entities/sessao_local.dart';
import '../repositories/sessao_local_repository.dart';

class BootstrapLocalSession {
  BootstrapLocalSession(this._repository);

  final SessaoLocalRepository _repository;

  Future<SessaoLocal?> call() {
    return _repository.getCurrentSession();
  }
}
