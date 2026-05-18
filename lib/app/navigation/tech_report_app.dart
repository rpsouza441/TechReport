import 'package:flutter/material.dart';
import 'package:techreport/app/theme/metric_slate_theme.dart';

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
import 'company_shell.dart';

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
          theme: MetricSlateTheme.light(),
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

      case AppBootstrapStatus.failed:
        return _BootstrapFailureScreen(
          message:
              bootstrapViewModel.errorMessage ??
              'Nao foi possivel iniciar o app.',
          onRetry: bootstrapViewModel.bootstrap,
          onResetMode: bootstrapViewModel.requireModeChoice,
        );

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

        return CompanyShell(
          scope: scope,
          session: session,
          onSignOut: () async {
            await scope.signOutCompany();
            bootstrapViewModel.requireRemoteLogin();
          },
        );
    }
  }
}

class _BootstrapFailureScreen extends StatelessWidget {
  const _BootstrapFailureScreen({
    required this.message,
    required this.onRetry,
    required this.onResetMode,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onResetMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Falha ao iniciar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onResetMode,
                  child: const Text('Voltar para escolha de modo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
