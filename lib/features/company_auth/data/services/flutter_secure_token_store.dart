import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:techreport/features/company_auth/data/services/secure_token_store.dart';

class FlutterSecureTokenStore implements SecureTokenStore {
  FlutterSecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: SecureTokenStore.accessTokenRef,
      value: accessToken,
    );
    await _storage.write(
      key: SecureTokenStore.refreshTokenRef,
      value: refreshToken,
    );
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: SecureTokenStore.accessTokenRef);
  }

  @override
  Future<String?> readRefreshToken() {
    return _storage.read(key: SecureTokenStore.refreshTokenRef);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: SecureTokenStore.accessTokenRef);
    await _storage.delete(key: SecureTokenStore.refreshTokenRef);
  }
}
