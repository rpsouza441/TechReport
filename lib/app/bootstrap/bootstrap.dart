import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../di/app_scope.dart';
import '../navigation/tech_report_app.dart';
import '../theme/metric_slate_theme.dart';
import '../../shared/infra/debug/app_error_log.dart';
import '../../shared/infra/debug/local_database_debug_log.dart';
import '../../shared/infra/database/open_encrypted_database.dart';
import '../../shared/infra/security/database_key_store.dart';

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

      // Log de auditoria em release: nao expõe dados sensíveis (chave, stack trace).
      _logBootstrapScopeAuditFailure(error);

      rethrow;
    }
  }

  /// Log estruturado de auditoria para falhas em [_createScope].
  /// Coleta dados booleanos sem expor informacoes sensiveis.
  static Future<void> _logBootstrapScopeAuditFailure(Object error) async {
    bool? fileExists;
    bool? keyExists;

    try {
      final dbFile = await resolveLocalDatabaseFile();
      fileExists = dbFile.existsSync();
    } catch (e, st) {
      debugPrint('Error checking database file: $e\n$st');
      // ignora — dados de diagnostico apenas
    }

    try {
      final keyStore = DatabaseKeyStore();
      final key = await keyStore.readKey();
      keyExists = key != null;
    } catch (e, st) {
      debugPrint('Error reading key store: $e\n$st');
      // ignora — dados de diagnostico apenas
    }

    LocalDatabaseDebugLog.audit(
      'bootstrap.scope.audit',
      data: {
        'exceptionType': error.runtimeType.toString(),
        'fileExists': fileExists,
        'keyExists': keyExists,
      },
    );
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
          darkTheme: MetricSlateTheme.dark(),
          themeMode: ThemeMode.system,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: error == null
                    ? const _BootstrapSplash()
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

class _BootstrapSplash extends StatelessWidget {
  const _BootstrapSplash();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/branding/techreport_logo.png',
              width: 112,
              height: 112,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'TechReport',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Preparando o TechReport...',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
