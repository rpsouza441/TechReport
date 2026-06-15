import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_theme_mode.dart';
import 'app_theme_variant.dart';

class AppThemeRepository {
  AppThemeRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _variantKey = 'app_theme_variant';
  static const _modeKey = 'app_theme_mode';

  final FlutterSecureStorage _storage;

  Future<AppThemeVariant> loadVariant() async {
    final name = await _storage.read(key: _variantKey);
    return AppThemeVariant.fromName(name);
  }

  Future<void> saveVariant(AppThemeVariant variant) async {
    await _storage.write(key: _variantKey, value: variant.name);
  }

  Future<AppThemeModePreference> loadMode() async {
    final name = await _storage.read(key: _modeKey);
    return AppThemeModePreference.fromName(name);
  }

  Future<void> saveMode(AppThemeModePreference mode) async {
    await _storage.write(key: _modeKey, value: mode.name);
  }

  Future<void> clear() async {
    await _storage.delete(key: _variantKey);
    await _storage.delete(key: _modeKey);
  }
}
