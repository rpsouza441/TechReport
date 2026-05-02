import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';

abstract class RemoteSessionRepository {
  Future<SessaoRemota?> getSession();

  Future<void> saveSession(SessaoRemota session);

  Future<void> updateSession(SessaoRemota session);

  Future<void> deleteSession();

  Future<bool> hasSession();
}
