import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class LocalDatabaseDebugLog {
  static const _name = 'techreport.local-db';

  static void info(String message, {Object? data}) {
    if (!kDebugMode) return;

    final line = data == null ? message : '$message | $data';
    debugPrint('$_name: $line');
    developer.log(line, name: _name);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    if (!kDebugMode) return;

    final line = data == null ? message : '$message | $data';
    debugPrint('$_name: $line');
    developer.log(line, name: _name, error: error, stackTrace: stackTrace);
  }
}
