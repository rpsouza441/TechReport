import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';

abstract class AuthRepository {
  Future<SessaoRemota> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<SessaoRemota?> restoreSession();

  Future<SessaoRemota?> refreshSession();

  Future<SessaoRemota?> currentSession();
}
