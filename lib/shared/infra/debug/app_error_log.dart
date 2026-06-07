import 'dart:developer' as developer;
import 'dart:math' show min;

import 'package:flutter/foundation.dart';

class AppErrorLog {
  static const _name = 'techreport.errors';

  static void flutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
      debugPrint('$_name: flutter.error | ${details.exception}');
      developer.log(
        'flutter.error',
        name: _name,
        error: details.exception,
        stackTrace: details.stack,
      );
    } else {
      // In release: log exception type only, no stack trace — no user-visible
      // crash. The FutureBuilder in bootstrap.dart shows a friendly message for
      // scope creation failures. Other runtime errors are logged silently so
      // the app can continue.
      developer.log(
        'flutter.error',
        name: _name,
        error: details.exceptionAsString().substring(
          0,
          min(100, details.exceptionAsString().length),
        ),
      );
    }
  }

  static void uncaught(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('$_name: uncaught | $error');
      developer.log(
        'uncaught',
        name: _name,
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // In release: log truncated error message — no stack trace or sensitive
      // details exposed to the user. The app continues; the Flutter
      // FutureBuilder in bootstrap.dart handles user-facing bootstrap errors.
      developer.log(
        'uncaught (release)',
        name: _name,
        error: error.toString().substring(
          0,
          min(100, error.toString().length),
        ),
      );
    }
  }
}
