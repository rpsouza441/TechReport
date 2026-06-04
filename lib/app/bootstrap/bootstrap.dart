import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../di/app_scope.dart';
import '../navigation/tech_report_app.dart';
import '../theme/metric_slate_theme.dart';
import '../../shared/infra/debug/app_error_log.dart';
import '../../shared/infra/debug/local_database_debug_log.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  _configureGlobalErrorHandling();
  runApp(const _TechReportBootstrapApp());
}

void _configureGlobalErrorHandling() {
  FlutterError.onError = AppErrorLog.flutterError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppErrorLog.uncaught(error, stackTrace);
    return true;
  };
}

class _TechReportBootstrapApp extends StatefulWidget {
  const _TechReportBootstrapApp();

  @override
  State<_TechReportBootstrapApp> createState() =>
      _TechReportBootstrapAppState();
}

class _TechReportBootstrapAppState extends State<_TechReportBootstrapApp> {
  late final Future<AppScope> _scopeFuture;

  @override
  void initState() {
    super.initState();
    _scopeFuture = _createScope();
  }

  Future<AppScope> _createScope() async {
    LocalDatabaseDebugLog.info('bootstrap.scope.start');
    try {
      final scope = await AppScope.create();
      LocalDatabaseDebugLog.info('bootstrap.scope.created');
      return scope;
    } catch (error, stackTrace) {
      LocalDatabaseDebugLog.error(
        'bootstrap.scope.failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppScope>(
      future: _scopeFuture,
      builder: (context, snapshot) {
        final scope = snapshot.data;
        if (scope != null) {
          return TechReportApp(scope: scope);
        }

        final error = snapshot.error;
        final errorMessage = kReleaseMode
            ? 'Nao foi possivel abrir os dados locais deste dispositivo. '
                  'Sera necessario redefinir os dados locais ou entrar novamente.'
            : '$error';
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MetricSlateTheme.light(),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: error == null
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Iniciando TechReport...'),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
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
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(errorMessage, textAlign: TextAlign.center),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
