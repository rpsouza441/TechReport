import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';

abstract class AppModeRepository {
  Future<AppModePreference?> getPreference();

  Future<void> savePreference(AppModePreference preference);

  Future<void> clearPreference();
}
