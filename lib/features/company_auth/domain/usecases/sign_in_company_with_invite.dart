import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';

class SignInCompanyWithInvite {
  SignInCompanyWithInvite({
    required AuthRepository authRepository,
    required RemoteSessionRepository remoteSessionRepository,
    required AppModeRepository appModeRepository,
  }) : _authRepository = authRepository,
       _remoteSessionRepository = remoteSessionRepository,
       _appModeRepository = appModeRepository;

  final AuthRepository _authRepository;
  final RemoteSessionRepository _remoteSessionRepository;
  final AppModeRepository _appModeRepository;

  Future<SignInCompanyWithInviteResult> call({
    required String email,
    required String password,
    required String codigoConvite,
    bool createAccount = false,
  }) async {
    try {
      final session = createAccount
          ? await _authRepository.signUpWithInvite(
              email: email,
              password: password,
              codigoConvite: codigoConvite,
            )
          : await _authRepository.signInWithInvite(
              email: email,
              password: password,
              codigoConvite: codigoConvite,
            );

      await _remoteSessionRepository.saveSession(session);

      await _appModeRepository.savePreference(
        AppModePreference(lastMode: AppMode.company, updatedAt: DateTime.now()),
      );

      return SignInCompanyWithInviteResult.success(session);
    } catch (e) {
      final message = _friendlyMessage(e);
      if (message.contains('Conta criada. Confirme o e-mail')) {
        return SignInCompanyWithInviteResult.pendingEmailConfirmation(message);
      }

      return SignInCompanyWithInviteResult.failure(_friendlyMessage(e));
    }
  }

  String _friendlyMessage(Object error) {
    final message = error.toString();
    const prefix = 'PostgrestException(message: ';
    if (message.contains(prefix)) {
      final start = message.indexOf(prefix) + prefix.length;
      final end = message.indexOf(',', start);
      if (end > start) {
        return message.substring(start, end);
      }
    }

    if (message.contains('asyncStorage') || message.contains('pkce')) {
      return 'Nao foi possivel iniciar a criacao da conta. '
          'Atualize o app e tente novamente.';
    }

    return message.replaceFirst('RemoteAuthException: ', '');
  }
}

class SignInCompanyWithInviteResult {
  const SignInCompanyWithInviteResult._({
    required this.success,
    this.pendingEmailConfirmation = false,
    this.session,
    this.errorMessage,
  });

  const SignInCompanyWithInviteResult.success(SessaoRemota session)
    : this._(success: true, session: session);

  const SignInCompanyWithInviteResult.pendingEmailConfirmation(String message)
    : this._(
        success: false,
        pendingEmailConfirmation: true,
        errorMessage: message,
      );

  const SignInCompanyWithInviteResult.failure(String errorMessage)
    : this._(success: false, errorMessage: errorMessage);

  final bool success;
  final bool pendingEmailConfirmation;
  final SessaoRemota? session;
  final String? errorMessage;
}
