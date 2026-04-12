import '../entities/sessao_local.dart';

abstract class SessaoLocalRepository {
  Future<SessaoLocal?> getCurrentSession();

  Future<void> saveSession(SessaoLocal session);

  Future<void> deleteSession();
}
