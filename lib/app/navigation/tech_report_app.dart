import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:techreport/app/theme/metric_slate_theme.dart';

import '../../features/company_auth/presentation/screens/app_mode_choice_screen.dart';
import '../../features/company_auth/presentation/screens/company_sign_in_screen.dart';
import '../../features/company_auth/presentation/screens/company_accept_invite_screen.dart';
import '../../features/company_auth/presentation/view_models/company_accept_invite_view_model.dart';
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
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  Uri? _pendingDeepLink;
  bool _deepLinkHandled = false;

  @override
  void initState() {
    super.initState();

    bootstrapViewModel = AppBootstrapViewModel(
      localSessionViewModel: widget.scope.appSessionViewModel,
      bootstrapCompanySession: widget.scope.bootstrapCompanySession,
      selectAppMode: widget.scope.selectAppMode,
    );

    bootstrapViewModel.bootstrap();

    _appLinks.uriLinkStream.listen((uri) {
      _pendingDeepLink = uri;
    });
  }

  void _handleDeepLink() {
    final uri = _pendingDeepLink;
    if (uri == null) return;

    _pendingDeepLink = null;

    if (uri.scheme != 'techreport' || uri.host != 'convite') return;

    final codigoParam = uri.queryParameters['codigo'];
    final codigo = (codigoParam != null && codigoParam.trim().isNotEmpty)
        ? codigoParam.trim().toUpperCase()
        : null;

    final viewModel = CompanyAcceptInviteViewModel(
      signInCompanyWithInvite: widget.scope.signInCompanyWithInvite,
      authRepository: widget.scope.authRepository,
      codigo: codigo,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CompanyAcceptInviteScreen(
          viewModel: viewModel,
          onAccepted: bootstrapViewModel.unlockCompany,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = widget.scope.appThemeViewModel;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Tech Report',
      theme: themeViewModel.loaded
          ? themeViewModel.currentTheme
          : MetricSlateTheme.light(),
      home: AnimatedBuilder(
        animation: Listenable.merge([bootstrapViewModel, themeViewModel]),
        builder: (context, _) {
          if (!_deepLinkHandled && bootstrapViewModel.status != AppBootstrapStatus.loading) {
            _deepLinkHandled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleDeepLink();
            });
          }
          return AppShell(
            bootstrapViewModel: bootstrapViewModel,
            scope: widget.scope,
            rootNavigatorKey: _navigatorKey,
          );
        },
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.bootstrapViewModel,
    required this.scope,
    required this.rootNavigatorKey,
  });

  final AppBootstrapViewModel bootstrapViewModel;
  final AppScope scope;
  final GlobalKey<NavigatorState> rootNavigatorKey;

  @override
  Widget build(BuildContext context) {
    switch (bootstrapViewModel.status) {
      case AppBootstrapStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AppBootstrapStatus.failed:
        return _BootstrapFailureScreen(
          message:
              bootstrapViewModel.errorMessage ??
              'Não foi possível iniciar o app.',
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
          onCompleted: bootstrapViewModel.syncLocalStatus,
          onBackToModeChoice: bootstrapViewModel.requireModeChoice,
        );

      case AppBootstrapStatus.localLocked:
        return LocalUnlockScreen(
          viewModel: scope.appSessionViewModel,
          onUnlocked: bootstrapViewModel.syncLocalStatus,
        );

      case AppBootstrapStatus.localUnlocked:
        return LocalHomeScreen(
          viewModel: scope.appSessionViewModel,
          assinaturaRepository: scope.assinaturaRepository,
          applyLocalDataImport: scope.applyLocalDataImport,
          localBackupParser: scope.localBackupParser,
          localBackupService: scope.localBackupService,
          localDataImportParser: scope.localDataImportParser,
          localDataExportShareService: scope.localDataExportShareService,
          localSignatureAssetStore: scope.localSignatureAssetStore,
          previewLocalDataImport: scope.previewLocalDataImport,
          ratPdfShareService: scope.ratPdfShareService,
          ratRepository: scope.ratRepository,
          shareRatLocally: scope.shareRatLocally,
          onLocalLocked: bootstrapViewModel.syncLocalStatus,
          onSwitchMode: bootstrapViewModel.chooseCompany,
          themeViewModel: scope.appThemeViewModel,
          tecnicoLocalRepository: scope.tecnicoLocalRepository,
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
          key: const ValueKey('remoteLoginRequired'),
          viewModel: CompanySignInViewModel(signInCompany: scope.signInCompany),
          onSignedIn: bootstrapViewModel.unlockCompany,
          onCancel: bootstrapViewModel.requireModeChoice,
          onAcceptInvite: () => _openAcceptInvite(context),
        );

      case AppBootstrapStatus.companyUnlocked:
        final session = bootstrapViewModel.remoteSession;

        if (session == null) {
          return CompanySignInScreen(
            key: const ValueKey('companyUnlockedWithoutSession'),
            viewModel: CompanySignInViewModel(
              signInCompany: scope.signInCompany,
            ),
            onSignedIn: bootstrapViewModel.unlockCompany,
            onCancel: bootstrapViewModel.requireModeChoice,
            onAcceptInvite: () => _openAcceptInvite(context),
          );
        }

        return CompanyShell(
          key: ValueKey('companyUnlocked-${session.usuarioId}'),
          scope: scope,
          session: session,
          onSignOut: () async {
            await scope.signOutCompany();
            rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            bootstrapViewModel.requireRemoteLogin();
          },
        );
    }
  }

  void _openAcceptInvite(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CompanyAcceptInviteScreen(
          viewModel: CompanyAcceptInviteViewModel(
            signInCompanyWithInvite: scope.signInCompanyWithInvite,
            authRepository: scope.authRepository,
          ),
          onAccepted: bootstrapViewModel.unlockCompany,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
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
