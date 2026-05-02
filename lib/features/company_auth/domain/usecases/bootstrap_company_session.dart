import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';

enum CompanyBootstrapStatus {
  localMode,
  endpointRequired,
  loginRequired,
  sessionReady,
  offlineAllowed,
}

class BootstrapCompanySession {
  BootstrapCompanySession({
    required AppModeRepository appModeRepository,
    required AuthRepository authRepository,
  }) : _appModeRepository = appModeRepository,
       _authRepository = authRepository;

  final AppModeRepository _appModeRepository;
  final AuthRepository _authRepository;

  Future<CompanyBootstrapStatus> call() async {
    final preference = await _appModeRepository.getPreference();

    if (preference == null || preference.isLocal) {
      return CompanyBootstrapStatus.localMode;
    }

    final session = await _authRepository.restoreSession();

    if (session == null) {
      return CompanyBootstrapStatus.loginRequired;
    }

    switch (session.status) {
      case SessaoRemotaStatus.valid:
        return CompanyBootstrapStatus.sessionReady;
      case SessaoRemotaStatus.offlineAllowed:
        return CompanyBootstrapStatus.offlineAllowed;
      case SessaoRemotaStatus.expired:
      case SessaoRemotaStatus.invalid:
        return CompanyBootstrapStatus.loginRequired;
    }
  }
}
