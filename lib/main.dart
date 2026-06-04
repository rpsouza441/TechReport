import 'dart:async';

import 'app/bootstrap/bootstrap.dart';
import 'shared/infra/debug/app_error_log.dart';

void main() {
  runZonedGuarded(bootstrap, AppErrorLog.uncaught);
}
