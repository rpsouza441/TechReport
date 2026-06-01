abstract class SecureTokenStore {
  static const accessTokenRef = 'company_auth.access_token';
  static const refreshTokenRef = 'company_auth.refresh_token';
  static const pendingInviteEmailRef = 'company_auth.pending_invite.email';
  static const pendingInviteCodeRef = 'company_auth.pending_invite.code';
  static const pendingInviteCreatedAtRef =
      'company_auth.pending_invite.created_at';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> clearTokens();

  Future<void> savePendingInvite({
    required String email,
    required String codigoConvite,
  });

  Future<PendingCompanyInvite?> readPendingInvite();

  Future<void> clearPendingInvite();
}

class PendingCompanyInvite {
  const PendingCompanyInvite({
    required this.email,
    required this.codigoConvite,
    required this.createdAt,
  });

  final String email;
  final String codigoConvite;
  final DateTime createdAt;
}
