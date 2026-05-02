import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';

class SignOutCompany {
  SignOutCompany({
    required AuthRepository authRepository,
    required RemoteSessionRepository remoteSessionRepository,
    required AppModeRepository appModeRepository,
  }) : _authRepository = authRepository,
       _remoteSessionRepository = remoteSessionRepository,
       _appModeRepository = appModeRepository;

  final AuthRepository _authRepository;
  final RemoteSessionRepository _remoteSessionRepository;
  final AppModeRepository _appModeRepository;

  Future<SignOutCompanyResult> call() async {
    Object? remoteError;
    try {
      await _authRepository.signOut();
    } catch (e) {
      remoteError = e;
    } finally {
      await _remoteSessionRepository.deleteSession();
      await _appModeRepository.savePreference(
        AppModePreference(lastMode: AppMode.local, updatedAt: DateTime.now()),
      );
    }
    if (remoteError != null) {
      return SignOutCompanyResult.remoteFailedButLocalCleared(
        remoteError.toString(),
      );
    }

    return const SignOutCompanyResult.success();
  }
}

class SignOutCompanyResult {
  const SignOutCompanyResult._({
    required this.localCleared,
    required this.remoteConfirmed,
    this.warningMessage,
  });

  const SignOutCompanyResult.success()
    : this._(localCleared: true, remoteConfirmed: true);

  const SignOutCompanyResult.remoteFailedButLocalCleared(String warningMessage)
    : this._(
        localCleared: true,
        remoteConfirmed: false,
        warningMessage: warningMessage,
      );

  final bool localCleared;
  final bool remoteConfirmed;
  final String? warningMessage;

  bool get hasWarning => warningMessage != null;
}
