import 'package:flutter/material.dart';
import 'package:techreport/features/rat/presentation/screens/rat_list_screen.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_view_model.dart';

import '../../features/company_auth/presentation/screens/app_mode_choice_screen.dart';
import '../../features/company_auth/presentation/screens/company_sign_in_screen.dart';
import '../../features/company_auth/presentation/screens/remote_server_config_screen.dart';
import '../../features/company_auth/presentation/view_models/app_mode_choice_view_model.dart';
import '../../features/company_auth/presentation/view_models/company_sign_in_view_model.dart';
import '../../features/company_auth/presentation/view_models/remote_server_config_view_model.dart';
import '../../features/local_auth/presentation/screens/local_home_screen.dart';
import '../../features/local_auth/presentation/screens/local_onboarding_screen.dart';
import '../../features/local_auth/presentation/screens/local_unlock_screen.dart';
import '../di/app_scope.dart';
import 'app_bootstrap_view_model.dart';

class TechReportApp extends StatefulWidget {
  const TechReportApp({super.key, required this.scope});

  final AppScope scope;

  @override
  State<TechReportApp> createState() => _TechReportAppState();
}

class _TechReportAppState extends State<TechReportApp> {
  late final AppBootstrapViewModel bootstrapViewModel;

  @override
  void initState() {
    super.initState();

    bootstrapViewModel = AppBootstrapViewModel(
      localSessionViewModel: widget.scope.appSessionViewModel,
      bootstrapCompanySession: widget.scope.bootstrapCompanySession,
      selectAppMode: widget.scope.selectAppMode,
    );

    bootstrapViewModel.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bootstrapViewModel,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tech Report',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF4F7F5),
            useMaterial3: true,
          ),
          home: AppShell(
            bootstrapViewModel: bootstrapViewModel,
            scope: widget.scope,
          ),
        );
      },
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.bootstrapViewModel,
    required this.scope,
  });

  final AppBootstrapViewModel bootstrapViewModel;
  final AppScope scope;

  @override
  Widget build(BuildContext context) {
    switch (bootstrapViewModel.status) {
      case AppBootstrapStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AppBootstrapStatus.modeChoiceRequired:
        return AppModeChoiceScreen(
          viewModel: AppModeChoiceViewModel(selectAppMode: scope.selectAppMode),
          onCompanySelected: bootstrapViewModel.requireRemoteEndpoint,
          onLocalSelected: bootstrapViewModel.chooseLocal,
        );

      case AppBootstrapStatus.localOnboarding:
        return LocalOnboardingScreen(
          viewModel: scope.appSessionViewModel,
          onBackToModeChoice: bootstrapViewModel.requireModeChoice,
        );

      case AppBootstrapStatus.localLocked:
        return LocalUnlockScreen(viewModel: scope.appSessionViewModel);

      case AppBootstrapStatus.localUnlocked:
        return LocalHomeScreen(
          viewModel: scope.appSessionViewModel,
          assinaturaRepository: scope.assinaturaRepository,
          localSignatureAssetStore: scope.localSignatureAssetStore,
          ratPdfShareService: scope.ratPdfShareService,
          ratRepository: scope.ratRepository,
          shareRatLocally: scope.shareRatLocally,
        );

      case AppBootstrapStatus.remoteEndpointRequired:
        return RemoteServerConfigScreen(
          viewModel: RemoteServerConfigViewModel(
            remoteEndpointRepository: scope.remoteEndpointRepository,
          ),
          onSaved: bootstrapViewModel.requireRemoteLogin,
          onCancel: bootstrapViewModel.requireModeChoice,
        );

      case AppBootstrapStatus.remoteLoginRequired:
        return CompanySignInScreen(
          viewModel: CompanySignInViewModel(signInCompany: scope.signInCompany),
          onSignedIn: bootstrapViewModel.unlockCompany,
          onCancel: bootstrapViewModel.requireModeChoice,
        );

      case AppBootstrapStatus.companyUnlocked:
        final session = bootstrapViewModel.remoteSession;

        if (session == null) {
          return CompanySignInScreen(
            viewModel: CompanySignInViewModel(
              signInCompany: scope.signInCompany,
            ),
            onSignedIn: bootstrapViewModel.unlockCompany,
            onCancel: bootstrapViewModel.requireModeChoice,
          );
        }

        final ratListScope = session.isGerente
            ? RatListScope.companyManager(empresaId: session.empresaId)
            : RatListScope.companyTechnician(
                empresaId: session.empresaId,
                tecnicoId: session.tecnicoId,
              );

        return RatListScreen(
          viewModel: RatListViewModel(
            assinaturaRepository: scope.assinaturaRepository,
            ratRepository: scope.ratRepository,
            scope: ratListScope,
          ),
          assinaturaRepository: scope.assinaturaRepository,
          localSignatureAssetStore: scope.localSignatureAssetStore,
          ratPdfShareService: scope.ratPdfShareService,
          ratRepository: scope.ratRepository,
          shareRatLocally: scope.shareRatLocally,
          remoteSession: session,
          enqueueRatSync: scope.enqueueRatSync,
          processSyncQueue: scope.processSyncQueue,
          downloadRemoteRats: scope.downloadRemoteRats,
          onSignOut: () async {
            await scope.signOutCompany();
            bootstrapViewModel.requireRemoteLogin();
          },
        );
    }
  }
}
