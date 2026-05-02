abstract class SecureTokenStore {
  static const accessTokenRef = 'company_auth.access_token';
  static const refreshTokenRef = 'company_auth.refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> clearTokens();
}
