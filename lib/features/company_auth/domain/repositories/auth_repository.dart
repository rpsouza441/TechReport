import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';

abstract class AuthRepository {
  Future<SessaoRemota> signIn({
    required String email,
    required String password,
  });

  Future<SessaoRemota> signInWithInvite({
    required String email,
    required String password,
    required String codigoConvite,
  });

  Future<SessaoRemota> signUpWithInvite({
    required String email,
    required String password,
    required String codigoConvite,
  });

  Future<void> signOut();

  Future<SessaoRemota?> restoreSession();

  Future<SessaoRemota?> refreshSession();

  Future<SessaoRemota?> currentSession();

  Future<void> changePassword(String newPassword);

  Future<void> resendConfirmationEmail({required String email});

  Future<void> updateOwnDisplayName(String name);
}
