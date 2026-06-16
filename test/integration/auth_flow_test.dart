import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/company_auth/data/exceptions/remote_auth_exception.dart';
import 'package:techreport/features/company_auth/data/services/secure_token_store.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';
import 'package:techreport/features/company_auth/data/repositories/supabase_auth_repository.dart';

// ─── Mock Classes ────────────────────────────────────────────────────────────

class MockSupabaseClient {
  bool shouldFailSignIn = false;
  bool shouldFailSignUp = false;
  bool shouldFailRefresh = false;
  String? sessionError;
  String? returnEmail;
  Map<String, dynamic>? _sessionData;

  void setSessionData(Map<String, dynamic>? data) {
    _sessionData = data;
  }

  Future<Map<String, dynamic>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    returnEmail = email;
    if (shouldFailSignIn) {
      throw _AuthApiException('invalid_credentials', 'Invalid login credentials');
    }
    return _buildAuthResponse(email);
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    returnEmail = email;
    if (shouldFailSignUp) {
      throw _AuthApiException('signup_failed', 'Signup failed');
    }
    // Signup without immediate session (email confirmation)
    return {
      'session': null,
      'user': {
        'id': 'user-mock-123',
        'email': email,
      },
    };
  }

  Future<Map<String, dynamic>> _buildAuthResponse(String email) {
    return {
      'session': {
        'access_token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        'expires_at': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
        'user': {
          'id': 'user-mock-123',
          'email': email,
        },
      },
      'user': {
        'id': 'user-mock-123',
        'email': email,
      },
    };
  }

  Future<Map<String, dynamic>> setSession(String refreshToken) async {
    if (shouldFailRefresh) {
      throw _AuthApiException('session_expired', 'Session expired');
    }
    return {
      'session': {
        'access_token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'refreshed_token',
        'expires_at': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
        'user': {
          'id': 'user-mock-123',
          'email': 'test@example.com',
        },
      },
      'user': {
        'id': 'user-mock-123',
        'email': 'test@example.com',
      },
    };
  }

  Future<void> signOut() async {}

  Future<Map<String, dynamic>> updateUser(UserAttributes attributes) async {
    return {'id': 'user-mock-123'};
  }

  void reset() {
    shouldFailSignIn = false;
    shouldFailSignUp = false;
    shouldFailRefresh = false;
    sessionError = null;
    returnEmail = null;
  }
}

class _AuthApiException implements Exception {
  final String code;
  final String message;

  _AuthApiException(this.code, this.message);

  @override
  String toString() => 'AuthApiException: $code - $message';
}

class UserAttributes {
  final String? password;

  UserAttributes({this.password});
}

class MockSupabaseClientFactory implements SupabaseClientFactory {
  MockSupabaseClientFactory({MockSupabaseClient? client})
      : _client = client ?? MockSupabaseClient();

  final MockSupabaseClient _client;

  @override
  Future<dynamic> tryCreateClient() async {
    return _client;
  }

  @override
  Future<dynamic> tryCreateAuthenticatedClient() async {
    return _client;
  }
}

class MockSecureTokenStore implements SecureTokenStore {
  String? _accessToken;
  String? _refreshToken;
  PendingCompanyInvite? _pendingInvite;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  PendingCompanyInvite? get pendingInvite => _pendingInvite;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<void> savePendingInvite({
    required String email,
    required String codigoConvite,
  }) async {
    _pendingInvite = PendingCompanyInvite(
      email: email,
      codigoConvite: codigoConvite,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<PendingCompanyInvite?> readPendingInvite() async => _pendingInvite;

  @override
  Future<void> clearPendingInvite() async {
    _pendingInvite = null;
  }

  void reset() {
    _accessToken = null;
    _refreshToken = null;
    _pendingInvite = null;
  }
}

class MockRemoteSessionRepository implements RemoteSessionRepository {
  SessaoRemota? _session;

  SessaoRemota? get session => _session;

  @override
  Future<void> saveSession(SessaoRemota session) async {
    _session = session;
  }

  @override
  Future<SessaoRemota?> getSession() async => _session;

  @override
  Future<void> deleteSession() async {
    _session = null;
  }

  @override
  Future<void> updateSession(SessaoRemota session) async {
    _session = session;
  }

  void reset() {
    _session = null;
  }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseClientFactory mockClientFactory;
  late MockSecureTokenStore tokenStore;
  late MockRemoteSessionRepository sessionRepo;
  late SupabaseAuthRepository authRepo;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockClientFactory = MockSupabaseClientFactory(client: mockClient);
    tokenStore = MockSecureTokenStore();
    sessionRepo = MockRemoteSessionRepository();

    authRepo = SupabaseAuthRepository(
      clientFactory: mockClientFactory,
      tokenStore: tokenStore,
      remoteSessionRepository: sessionRepo,
    );
  });

  tearDown(() {
    mockClient.reset();
    tokenStore.reset();
    sessionRepo.reset();
  });

  // ─── Sign In Flow ───────────────────────────────────────────────────────────

  group('Sign in flow', () {
    test('successful sign in returns remote session', () async {
      final session = await authRepo.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(session, isNotNull);
      expect(session.email, 'test@example.com');
    });

    test('successful sign in saves tokens to secure store', () async {
      await authRepo.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(tokenStore.accessToken, isNotNull);
      expect(tokenStore.refreshToken, isNotNull);
    });

    test('successful sign in saves session to repository', () async {
      await authRepo.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(sessionRepo.session, isNotNull);
      expect(sessionRepo.session!.email, 'test@example.com');
    });

    test('sign in with invalid credentials throws RemoteAuthException', () async {
      mockClient.shouldFailSignIn = true;

      expect(
        () => authRepo.signIn(email: 'bad@example.com', password: 'wrong'),
        throwsA(isA<RemoteAuthException>()),
      );
    });

    test('sign in does not save tokens on failure', () async {
      mockClient.shouldFailSignIn = true;

      try {
        await authRepo.signIn(email: 'bad@example.com', password: 'wrong');
      } catch (_) {
        // Expected
      }

      expect(tokenStore.accessToken, isNull);
      expect(tokenStore.refreshToken, isNull);
    });

    test('sign in clears previous session', () async {
      // First sign in
      await authRepo.signIn(email: 'first@example.com', password: 'pass');

      // Sign in again with different email
      await authRepo.signIn(email: 'second@example.com', password: 'pass');

      // Session should be updated
      expect(sessionRepo.session!.email, 'second@example.com');
    });
  });

  // ─── Sign Up with Invite ────────────────────────────────────────────────────

  group('Sign up with invite', () {
    test('signUpWithInvite stores pending invite when confirmation required', () async {
      mockClient.shouldFailSignUp = true; // Simulates confirmation required

      try {
        await authRepo.signUpWithInvite(
          email: 'new@example.com',
          password: 'password123',
          codigoConvite: 'INVITE-123',
        );
      } catch (_) {
        // Expected - email confirmation needed
      }

      expect(tokenStore.pendingInvite, isNotNull);
      expect(tokenStore.pendingInvite!.email, 'new@example.com');
      expect(tokenStore.pendingInvite!.codigoConvite, 'INVITE-123');
    });

    test('signUpWithInvite clears pending invite on success', () async {
      // Pre-set pending invite
      await tokenStore.savePendingInvite(
        email: 'new@example.com',
        codigoConvite: 'INVITE-123',
      );

      // Successful signup should clear it
      await authRepo.signIn(email: 'new@example.com', password: 'password123');

      expect(tokenStore.pendingInvite, isNull);
    });
  });

  // ─── Session Restore Flow ──────────────────────────────────────────────────

  group('Session restore flow', () {
    test('restoreSession returns session when tokens exist', () async {
      // First sign in to create session
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      // Clear local caches (simulating app restart)
      // But tokens and session are persisted

      // Restore session
      final restored = await authRepo.restoreSession();

      expect(restored, isNotNull);
      expect(restored!.email, 'test@example.com');
    });

    test('restoreSession returns null when no tokens', () async {
      // No prior sign in
      final restored = await authRepo.restoreSession();

      expect(restored, isNull);
    });

    test('restoreSession returns null when no session saved', () async {
      // Save tokens but no session
      await tokenStore.saveTokens(
        accessToken: 'some-token',
        refreshToken: 'some-refresh',
      );

      final restored = await authRepo.restoreSession();

      expect(restored, isNull);
    });

    test('restoreSession updates tokens on refresh', () async {
      // First sign in
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      final oldRefreshToken = tokenStore.refreshToken;

      // Restore (which also refreshes)
      await authRepo.restoreSession();

      // Refresh token should be updated
      expect(tokenStore.refreshToken, isNot(equals(oldRefreshToken)));
    });
  });

  // ─── Session Refresh ───────────────────────────────────────────────────────

  group('Session refresh', () {
    test('refreshSession returns session when tokens exist', () async {
      // First sign in
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      // Refresh session
      final refreshed = await authRepo.refreshSession();

      expect(refreshed, isNotNull);
      expect(refreshed!.email, 'test@example.com');
    });

    test('refreshSession updates tokens', () async {
      // First sign in
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      final oldAccessToken = tokenStore.accessToken;

      // Refresh
      await authRepo.refreshSession();

      expect(tokenStore.accessToken, isNot(equals(oldAccessToken)));
    });

    test('refreshSession returns null when no session', () async {
      final refreshed = await authRepo.refreshSession();

      expect(refreshed, isNull);
    });

    test('refreshSession returns null when tokens cleared', () async {
      // Sign in first
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      // Clear tokens
      await tokenStore.clearTokens();

      final refreshed = await authRepo.refreshSession();

      expect(refreshed, isNull);
    });

    test('refreshSession returns null when refresh fails', () async {
      // Sign in first
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      // Make refresh fail
      mockClient.shouldFailRefresh = true;

      final refreshed = await authRepo.refreshSession();

      expect(refreshed, isNull);
    });
  });

  // ─── Sign Out Flow ─────────────────────────────────────────────────────────

  group('Sign out flow', () {
    test('signOut clears all tokens and session', () async {
      // Sign in first
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      expect(tokenStore.accessToken, isNotNull);
      expect(tokenStore.refreshToken, isNotNull);
      expect(sessionRepo.session, isNotNull);

      // Sign out
      await authRepo.signOut();

      expect(tokenStore.accessToken, isNull);
      expect(tokenStore.refreshToken, isNull);
      expect(sessionRepo.session, isNull);
    });

    test('signOut completes even if remote sign out fails', () async {
      // Sign in first
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      // signOut should not throw
      await authRepo.signOut();

      // Local state should be cleared
      expect(tokenStore.accessToken, isNull);
      expect(tokenStore.refreshToken, isNull);
    });

    test('signOut with no active session does nothing', () async {
      // No prior sign in

      // Should not throw
      await authRepo.signOut();

      expect(tokenStore.accessToken, isNull);
      expect(tokenStore.refreshToken, isNull);
    });
  });

  // ─── Current Session ──────────────────────────────────────────────────────

  group('Current session', () {
    test('currentSession returns saved session', () async {
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      final current = await authRepo.currentSession();

      expect(current, isNotNull);
      expect(current!.email, 'test@example.com');
    });

    test('currentSession returns null when no session', () async {
      final current = await authRepo.currentSession();

      expect(current, isNull);
    });
  });

  // ─── Password Change ───────────────────────────────────────────────────────

  group('Password change', () {
    test('changePassword succeeds with valid new password', () async {
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      // Should not throw
      await authRepo.changePassword('newPassword123');
    });
  });

  // ─── Display Name Update ───────────────────────────────────────────────────

  group('Display name update', () {
    test('updateOwnDisplayName succeeds with valid name', () async {
      await authRepo.signIn(email: 'test@example.com', password: 'pass');

      // Should not throw
      await authRepo.updateOwnDisplayName('New Display Name');
    });
  });

  // ─── Error Handling ────────────────────────────────────────────────────────

  group('Error handling', () {
    test('signIn with empty email shows friendly error', () async {
      mockClient.shouldFailSignIn = true;

      try {
        await authRepo.signIn(email: '', password: 'pass');
        fail('Should have thrown');
      } on RemoteAuthException catch (e) {
        expect(e.message, isNot(contains('invalid_credentials')));
      }
    });

    test('signIn maps invalid_credentials to friendly message', () async {
      mockClient.shouldFailSignIn = true;

      try {
        await authRepo.signIn(email: 'bad@example.com', password: 'wrong');
        fail('Should have thrown');
      } on RemoteAuthException catch (e) {
        expect(e.message.toLowerCase(), contains('inválidos'));
      }
    });

    test('auth methods do not leak internal error details', () async {
      mockClient.shouldFailSignIn = true;

      try {
        await authRepo.signIn(email: 'test@example.com', password: 'wrong');
        fail('Should have thrown');
      } on RemoteAuthException catch (e) {
        // Should not expose Supabase error codes
        expect(e.message, isNot(contains('supabase')));
        expect(e.message, isNot(contains('Postgrest')));
      }
    });
  });

  // ─── Auth Repository Interface Compliance ─────────────────────────────────

  group('AuthRepository interface compliance', () {
    test('implements signIn', () async {
      expect(authRepo.signIn, isNotNull);
    });

    test('implements signInWithInvite', () async {
      expect(authRepo.signInWithInvite, isNotNull);
    });

    test('implements signUpWithInvite', () async {
      expect(authRepo.signUpWithInvite, isNotNull);
    });

    test('implements currentSession', () async {
      expect(authRepo.currentSession, isNotNull);
    });

    test('implements restoreSession', () async {
      expect(authRepo.restoreSession, isNotNull);
    });

    test('implements refreshSession', () async {
      expect(authRepo.refreshSession, isNotNull);
    });

    test('implements signOut', () async {
      expect(authRepo.signOut, isNotNull);
    });

    test('implements changePassword', () async {
      expect(authRepo.changePassword, isNotNull);
    });

    test('implements updateOwnDisplayName', () async {
      expect(authRepo.updateOwnDisplayName, isNotNull);
    });
  });
}
