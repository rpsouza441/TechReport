import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:techreport/features/company_auth/domain/entities/app_mode_preference.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';

class LocalAppModeRepository implements AppModeRepository {
  LocalAppModeRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _preferenceKey = 'company_auth.app_mode_preference';

  final FlutterSecureStorage _storage;

  @override
  Future<AppModePreference?> getPreference() async {
    final rawPreference = await _storage.read(key: _preferenceKey);
    if (rawPreference == null) {
      return null;
    }

    final json = jsonDecode(rawPreference) as Map<String, dynamic>;

    return AppModePreference(
      lastMode: AppMode.values.byName(json['lastMode'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Future<void> savePreference(AppModePreference preference) async {
    await _storage.write(
      key: _preferenceKey,
      value: jsonEncode({
        'lastMode': preference.lastMode.name,
        'updatedAt': preference.updatedAt.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> clearPreference() async {
    await _storage.delete(key: _preferenceKey);
  }
}
