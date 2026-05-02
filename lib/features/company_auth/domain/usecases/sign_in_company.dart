import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';

class SignInCompany {
  SignInCompany({
    required AuthRepository authRepository,
    required RemoteSessionRepository remoteSessionRepository,
    required AppModeRepository appModeRepository,
  }) : _authRepository = authRepository,
       _remoteSessionRepository = remoteSessionRepository,
       _appModeRepository = appModeRepository;

  final AuthRepository _authRepository;
  final RemoteSessionRepository _remoteSessionRepository;
  final AppModeRepository _appModeRepository;

  Future<SignInCompanyResult> call({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _authRepository.signIn(
        email: email,
        password: password,
      );

      await _remoteSessionRepository.saveSession(session);

      await _appModeRepository.savePreference(
        AppModePreference(lastMode: AppMode.company, updatedAt: DateTime.now()),
      );

      return SignInCompanyResult.success(session);
    } catch (e) {
      return SignInCompanyResult.failure(e.toString());
    }
  }
}

class SignInCompanyResult {
  const SignInCompanyResult._({
    required this.success,
    this.session,
    this.errorMessage,
  });

  const SignInCompanyResult.success(SessaoRemota session)
    : this._(success: true, session: session);

  const SignInCompanyResult.failure(String errorMessage)
    : this._(success: false, errorMessage: errorMessage);

  final bool success;
  final SessaoRemota? session;
  final String? errorMessage;
}
