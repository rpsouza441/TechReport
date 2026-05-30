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
  }) async {
    try {
      final session = await _authRepository.signInWithInvite(
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

    return message.replaceFirst('RemoteAuthException: ', '');
  }
}

class SignInCompanyWithInviteResult {
  const SignInCompanyWithInviteResult._({
    required this.success,
    this.session,
    this.errorMessage,
  });

  const SignInCompanyWithInviteResult.success(SessaoRemota session)
    : this._(success: true, session: session);

  const SignInCompanyWithInviteResult.failure(String errorMessage)
    : this._(success: false, errorMessage: errorMessage);

  final bool success;
  final SessaoRemota? session;
  final String? errorMessage;
}
