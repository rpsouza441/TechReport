import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppErrorLog {
  static const _name = 'techreport.errors';

  static void flutterError(FlutterErrorDetails details) {
    if (!kDebugMode) return;

    FlutterError.presentError(details);
    debugPrint('$_name: flutter.error | ${details.exception}');
    developer.log(
      'flutter.error',
      name: _name,
      error: details.exception,
      stackTrace: details.stack,
    );
  }

  static void uncaught(Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;

    debugPrint('$_name: uncaught | $error');
    developer.log(
      'uncaught',
      name: _name,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
