import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';
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
    required RemoteEndpointRepository remoteEndpointRepository,
  }) : _localSessionViewModel = localSessionViewModel,
       _bootstrapCompanySession = bootstrapCompanySession,
       _selectAppMode = selectAppMode,
       _remoteEndpointRepository = remoteEndpointRepository;

  final AppSessionViewModel _localSessionViewModel;
  final BootstrapCompanySession _bootstrapCompanySession;
  final SelectAppMode _selectAppMode;
  final RemoteEndpointRepository _remoteEndpointRepository;

  bool _isChangingServer = false;
  AppBootstrapStatus status = AppBootstrapStatus.loading;
  SessaoRemota? remoteSession;
  String? errorMessage;

  bool get isChangingServer => _isChangingServer;

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

    final hasEndpoint = await _hasSavedEndpoint();
    if (hasEndpoint) {
      requireRemoteLogin();
    } else {
      requireRemoteEndpoint();
    }
  }

  Future<bool> _hasSavedEndpoint() async {
    try {
      final endpoint = await _remoteEndpointRepository.getActiveEndpoint();
      return endpoint != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> requireModeChoice() async {
    await _selectAppMode.clear();
    _isChangingServer = false;
    remoteSession = null;
    status = AppBootstrapStatus.modeChoiceRequired;
    notifyListeners();
  }

  void requireRemoteEndpoint({bool isChangingServer = false}) {
    _isChangingServer = isChangingServer;
    status = AppBootstrapStatus.remoteEndpointRequired;
    notifyListeners();
  }

  void requireRemoteLogin() {
    _isChangingServer = false;
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
