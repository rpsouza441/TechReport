import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:techreport/features/company_auth/data/exceptions/remote_auth_exception.dart';
import 'package:techreport/features/company_auth/data/services/secure_token_store.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SupabaseClientFactory clientFactory,
    required SecureTokenStore tokenStore,
    required RemoteSessionRepository remoteSessionRepository,
  }) : _clientFactory = clientFactory,
       _tokenStore = tokenStore,
       _remoteSessionRepository = remoteSessionRepository;

  final SupabaseClientFactory _clientFactory;
  final SecureTokenStore _tokenStore;
  final RemoteSessionRepository _remoteSessionRepository;

  @override
  @override
  Future<SessaoRemota> signIn({
    required String email,
    required String password,
  }) async {
    final client = await requireClient();

    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final session = response.session;
    if (session == null) {
      throw const RemoteAuthException('Sessao remota nao foi retornada.');
    }

    final user = response.user;
    if (user == null) {
      throw const RemoteAuthException('Usuario remoto nao foi retornado.');
    }

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const RemoteAuthException(
        'Refresh token remoto nao foi retornado.',
      );
    }

    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: refreshToken,
    );

    final remoteSession = buildRemoteSession(session: session, user: user);

    await _remoteSessionRepository.saveSession(remoteSession);

    return remoteSession;
  }

  @override
  Future<SessaoRemota?> currentSession() {
    return _remoteSessionRepository.getSession();
  }

  @override
  Future<SessaoRemota?> restoreSession() async {
    final savedSession = await _remoteSessionRepository.getSession();
    if (savedSession == null) {
      return null;
    }

    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _remoteSessionRepository.deleteSession();
      await _tokenStore.clearTokens();
      return null;
    }

    final client = await requireClient();

    final response = await client.auth.setSession(refreshToken);

    final session = response.session;
    final user = response.user;

    if (session == null || user == null) {
      return null;
    }

    final newRefreshToken = session.refreshToken;
    if (newRefreshToken == null || newRefreshToken.isEmpty) {
      return null;
    }

    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: newRefreshToken,
    );

    final restoredSession = buildRemoteSession(
      session: session,
      user: user,
      previousSession: savedSession,
    );

    await _remoteSessionRepository.updateSession(restoredSession);

    return restoredSession;
  }

  @override
  Future<SessaoRemota?> refreshSession() async {
    final savedSession = await _remoteSessionRepository.getSession();
    if (savedSession == null) {
      return null;
    }

    final client = await requireClient();

    final response = await client.auth.refreshSession();

    final session = response.session;
    final user = response.user;

    if (session == null || user == null) {
      return null;
    }

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: refreshToken,
    );

    final refreshedSession = buildRemoteSession(
      session: session,
      user: user,
      previousSession: savedSession,
    );

    await _remoteSessionRepository.updateSession(refreshedSession);

    return refreshedSession;
  }

  @override
  Future<void> signOut() async {
    try {
      final client = await _clientFactory.tryCreateClient();
      await client?.auth.signOut();
    } finally {
      await _tokenStore.clearTokens();
      await _remoteSessionRepository.deleteSession();
    }
  }

  Future<SupabaseClient> requireClient() async {
    final client = await _clientFactory.tryCreateClient();

    if (client == null) {
      throw const RemoteAuthException('Servidor remoto nao configurado.');
    }

    return client;
  }

  String requireMetadata(User user, String key) {
    final value = user.appMetadata[key];

    if (value is String && value.isNotEmpty) {
      return value;
    }

    throw RemoteAuthException('Metadata remota obrigatoria ausente: $key.');
  }

  SessaoRemota buildRemoteSession({
    required Session session,
    required User user,
    SessaoRemota? previousSession,
  }) {
    final now = DateTime.now();
    final expiresAt = session.expiresAt == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);

    return SessaoRemota(
      id: previousSession?.id ?? session.accessToken.hashCode.toString(),
      empresaId:
          previousSession?.empresaId ?? requireMetadata(user, 'empresaId'),
      usuarioId: user.id,
      tecnicoId:
          previousSession?.tecnicoId ?? requireMetadata(user, 'tecnicoId'),
      accessTokenRef: SecureTokenStore.accessTokenRef,
      refreshTokenRef: SecureTokenStore.refreshTokenRef,
      endpointRef: previousSession?.endpointRef ?? 'active',
      expiresAt: expiresAt,
      lastValidatedAt: now,
      offlineAccessUntil: now.add(const Duration(days: 7)),
      createdAt: previousSession?.createdAt ?? now,
      updatedAt: now,
    );
  }
}
