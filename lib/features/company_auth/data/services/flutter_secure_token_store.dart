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

  @override
  Future<void> savePendingInvite({
    required String email,
    required String codigoConvite,
  }) async {
    await _storage.write(
      key: SecureTokenStore.pendingInviteEmailRef,
      value: email.trim().toLowerCase(),
    );
    await _storage.write(
      key: SecureTokenStore.pendingInviteCodeRef,
      value: codigoConvite.trim().toUpperCase(),
    );
    await _storage.write(
      key: SecureTokenStore.pendingInviteCreatedAtRef,
      value: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<PendingCompanyInvite?> readPendingInvite() async {
    final email = await _storage.read(
      key: SecureTokenStore.pendingInviteEmailRef,
    );
    final code = await _storage.read(
      key: SecureTokenStore.pendingInviteCodeRef,
    );
    final createdAtText = await _storage.read(
      key: SecureTokenStore.pendingInviteCreatedAtRef,
    );

    if (email == null ||
        email.isEmpty ||
        code == null ||
        code.isEmpty ||
        createdAtText == null ||
        createdAtText.isEmpty) {
      return null;
    }

    return PendingCompanyInvite(
      email: email,
      codigoConvite: code,
      createdAt: DateTime.tryParse(createdAtText) ?? DateTime.now(),
    );
  }

  @override
  Future<void> clearPendingInvite() async {
    await _storage.delete(key: SecureTokenStore.pendingInviteEmailRef);
    await _storage.delete(key: SecureTokenStore.pendingInviteCodeRef);
    await _storage.delete(key: SecureTokenStore.pendingInviteCreatedAtRef);
  }
}
