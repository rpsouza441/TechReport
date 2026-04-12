import 'package:flutter/material.dart';

import '../di/app_scope.dart';
import '../navigation/tech_report_app.dart';

void bootstrap() {
  final scope = AppScope.create();
  runApp(TechReportApp(scope: scope));
}
