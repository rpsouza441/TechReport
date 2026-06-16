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

  /// Duration after which invite expires (7 days).
  static const expiryDuration = Duration(days: 7);

  /// Duration before expiry when warning should be shown (1 day).
  static const warningThreshold = Duration(days: 1);

  /// When this invite expires.
  DateTime get expiresAt => createdAt.add(expiryDuration);

  /// True if invite has already expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// True if invite is within warning window (less than 1 day remaining).
  bool get isExpiringSoon {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.inHours > 0 && remaining <= warningThreshold;
  }

  /// Human-readable remaining time.
  String get remainingTime {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.inDays > 0) {
      return '${remaining.inDays} dia${remaining.inDays > 1 ? 's' : ''}';
    }
    if (remaining.inHours > 0) {
      return '${remaining.inHours} hora${remaining.inHours > 1 ? 's' : ''}';
    }
    return '${remaining.inMinutes} minuto${remaining.inMinutes > 1 ? 's' : ''}';
  }
}
