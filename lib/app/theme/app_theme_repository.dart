import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_theme_variant.dart';

class AppThemeRepository {
  AppThemeRepository([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'app_theme_variant';

  final FlutterSecureStorage _storage;

  Future<AppThemeVariant> load() async {
    final name = await _storage.read(key: _key);
    return AppThemeVariant.fromName(name);
  }

  Future<void> save(AppThemeVariant variant) async {
    await _storage.write(key: _key, value: variant.name);
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
