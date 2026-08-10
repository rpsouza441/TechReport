import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the short-lived PKCE verifier required by GoTrue during sign-up.
class FlutterSecurePkceStorage extends GotrueAsyncStorage {
  FlutterSecurePkceStorage({
    required String endpointId,
    FlutterSecureStorage? storage,
  }) : _keyPrefix = 'company_auth.pkce.$endpointId.',
       _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(storageNamespace: 'TechReportSecure'),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  final String _keyPrefix;
  final FlutterSecureStorage _storage;

  String _namespaced(String key) => '$_keyPrefix$key';

  @override
  Future<String?> getItem({required String key}) {
    return _storage.read(key: _namespaced(key));
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    return _storage.write(key: _namespaced(key), value: value);
  }

  @override
  Future<void> removeItem({required String key}) {
    return _storage.delete(key: _namespaced(key));
  }
}
