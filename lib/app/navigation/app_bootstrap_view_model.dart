import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/usecases/bootstrap_company_session.dart';
import 'package:techreport/features/company_auth/domain/usecases/select_app_mode.dart';
import 'package:techreport/features/local_auth/presentation/view_models/app_session_view_model.dart';

enum AppBootstrapStatus {
  loading,
  failed,
  modeChoiceRequired,
  localOnboarding,
  localLocked,
  localUnlocked,
  remoteEndpointRequired,
  remoteLoginRequired,
  companyUnlocked,
}

class AppBootstrapViewModel extends ChangeNotifier {
  AppBootstrapViewModel({
    required AppSessionViewModel localSessionViewModel,
    required BootstrapCompanySession bootstrapCompanySession,
    required SelectAppMode selectAppMode,
  }) : _localSessionViewModel = localSessionViewModel,
       _bootstrapCompanySession = bootstrapCompanySession,
       _selectAppMode = selectAppMode;

  final AppSessionViewModel _localSessionViewModel;
  final BootstrapCompanySession _bootstrapCompanySession;
  final SelectAppMode _selectAppMode;

  AppBootstrapStatus status = AppBootstrapStatus.loading;
  SessaoRemota? remoteSession;
  String? errorMessage;

  Future<void> bootstrap() async {
    status = AppBootstrapStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _localSessionViewModel.bootstrap().timeout(
        const Duration(seconds: 8),
      );

      final companyBootstrap = await _bootstrapCompanySession().timeout(
        const Duration(seconds: 8),
      );

      switch (companyBootstrap.status) {
        case CompanyBootstrapStatus.modeChoiceRequired:
          status = AppBootstrapStatus.modeChoiceRequired;
          notifyListeners();
          return;
        case CompanyBootstrapStatus.localMode:
          _syncLocalStatus();
          return;
        case CompanyBootstrapStatus.endpointRequired:
          requireRemoteEndpoint();
          return;
        case CompanyBootstrapStatus.loginRequired:
          requireRemoteLogin();
          return;
        case CompanyBootstrapStatus.sessionReady:
        case CompanyBootstrapStatus.offlineAllowed:
          remoteSession = companyBootstrap.session;
          status = AppBootstrapStatus.companyUnlocked;
          notifyListeners();
          return;
      }
    } catch (error) {
      status = AppBootstrapStatus.failed;
      errorMessage = 'Falha ao iniciar o app: $error';
      notifyListeners();
    }
  }

  Future<void> chooseLocal() async {
    await _selectAppMode(AppMode.local);
    _syncLocalStatus();
  }

  Future<void> chooseCompany() async {
    await _selectAppMode(AppMode.company);
    requireRemoteEndpoint();
  }

  Future<void> requireModeChoice() async {
    await _selectAppMode.clear();
    remoteSession = null;
    status = AppBootstrapStatus.modeChoiceRequired;
    notifyListeners();
  }

  void requireRemoteEndpoint() {
    status = AppBootstrapStatus.remoteEndpointRequired;
    notifyListeners();
  }

  void requireRemoteLogin() {
    remoteSession = null;
    status = AppBootstrapStatus.remoteLoginRequired;
    notifyListeners();
  }

  void unlockCompany(SessaoRemota session) {
    remoteSession = session;
    status = AppBootstrapStatus.companyUnlocked;
    notifyListeners();
  }

  void syncLocalStatus() {
    _syncLocalStatus();
  }

  void _syncLocalStatus() {
    switch (_localSessionViewModel.status) {
      case AppSessionStatus.onboardingRequired:
        status = AppBootstrapStatus.localOnboarding;
      case AppSessionStatus.locked:
        status = AppBootstrapStatus.localLocked;
      case AppSessionStatus.unlocked:
        status = AppBootstrapStatus.localUnlocked;
    }

    notifyListeners();
  }
}
