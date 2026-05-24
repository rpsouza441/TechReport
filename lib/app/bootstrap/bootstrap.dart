import 'package:flutter/material.dart';

import '../di/app_scope.dart';
import '../navigation/tech_report_app.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _TechReportBootstrapApp());
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
    _scopeFuture = Future<AppScope>(AppScope.create);
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: error == null
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Iniciando TechReport...',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 16),
                          const Text(
                            'Falha ao iniciar',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text('$error', textAlign: TextAlign.center),
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
