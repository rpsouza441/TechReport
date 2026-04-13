import 'package:flutter/material.dart';

import '../../features/local_auth/presentation/screens/local_home_screen.dart';
import '../../features/local_auth/presentation/screens/local_onboarding_screen.dart';
import '../../features/local_auth/presentation/screens/local_unlock_screen.dart';
import '../../features/local_auth/presentation/view_models/app_session_view_model.dart';
import '../di/app_scope.dart';

class TechReportApp extends StatefulWidget {
  const TechReportApp({super.key, required this.scope});

  final AppScope scope;

  @override
  State<TechReportApp> createState() => _TechReportAppState();
}

class _TechReportAppState extends State<TechReportApp> {
  AppSessionViewModel get viewModel => widget.scope.appSessionViewModel;

  @override
  void initState() {
    super.initState();
    viewModel.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
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
          home: LocalSessionShell(viewModel: viewModel, scope: widget.scope),
        );
      },
    );
  }
}

class LocalSessionShell extends StatelessWidget {
  const LocalSessionShell({
    super.key,
    required this.viewModel,
    required this.scope,
  });

  final AppSessionViewModel viewModel;

  final AppScope scope;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (viewModel.status) {
      case AppSessionStatus.onboardingRequired:
        return LocalOnboardingScreen(viewModel: viewModel);
      case AppSessionStatus.locked:
        return LocalUnlockScreen(viewModel: viewModel);
      case AppSessionStatus.unlocked:
        return LocalHomeScreen(
          viewModel: viewModel,
          ratRepository: scope.ratRepository,
        );
    }
  }
}
