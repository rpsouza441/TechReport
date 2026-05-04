import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';

enum CompanyBootstrapStatus {
  modeChoiceRequired,
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

  Future<CompanyBootstrapResult> call() async {
    final preference = await _appModeRepository.getPreference();

    if (preference == null) {
      return const CompanyBootstrapResult(
        status: CompanyBootstrapStatus.modeChoiceRequired,
      );
    }

    if (preference.isLocal) {
      return const CompanyBootstrapResult(
        status: CompanyBootstrapStatus.localMode,
      );
    }

    final session = await _authRepository.restoreSession();

    if (session == null) {
      return const CompanyBootstrapResult(
        status: CompanyBootstrapStatus.loginRequired,
      );
    }

    switch (session.status) {
      case SessaoRemotaStatus.valid:
        return CompanyBootstrapResult(
          status: CompanyBootstrapStatus.sessionReady,
          session: session,
        );
      case SessaoRemotaStatus.offlineAllowed:
        return CompanyBootstrapResult(
          status: CompanyBootstrapStatus.offlineAllowed,
          session: session,
        );
      case SessaoRemotaStatus.expired:
      case SessaoRemotaStatus.invalid:
        return const CompanyBootstrapResult(
          status: CompanyBootstrapStatus.loginRequired,
        );
    }
  }
}

class CompanyBootstrapResult {
  const CompanyBootstrapResult({required this.status, this.session});

  final CompanyBootstrapStatus status;
  final SessaoRemota? session;
}
