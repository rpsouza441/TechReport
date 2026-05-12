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
  Future<SessaoRemota> signIn({
    required String email,
    required String password,
  }) async {
    final client = await requireClient();

    final AuthResponse response;
    try {
      response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthApiException catch (e) {
      throw mapAuthException(e);
    }

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

    final remoteSession = await buildRemoteSession(
      client: client,
      session: session,
      user: user,
    );

    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: refreshToken,
    );

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

    final restoredSession = await buildRemoteSession(
      client: client,
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

    final savedRefreshToken = await _tokenStore.readRefreshToken();
    if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
      await _remoteSessionRepository.deleteSession();
      await _tokenStore.clearTokens();
      return null;
    }

    final client = await requireClient();

    final response = await client.auth.setSession(savedRefreshToken);

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

    final refreshedSession = await buildRemoteSession(
      client: client,
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
      final client = await _clientFactory.tryCreateAuthenticatedClient();
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

  RemoteAuthException mapAuthException(AuthApiException exception) {
    if (exception.code == 'invalid_credentials') {
      return const RemoteAuthException('Email ou senha invalidos.');
    }

    return const RemoteAuthException(
      'Nao foi possivel entrar. Confira os dados e tente novamente.',
    );
  }

  Future<SessaoRemota> buildRemoteSession({
    required SupabaseClient client,
    required Session session,
    required User user,
    SessaoRemota? previousSession,
  }) {
    final now = DateTime.now();
    final expiresAt = session.expiresAt == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);

    return _fetchTecnicoProfile(client: client, user: user).then((profile) {
      return SessaoRemota(
        id: previousSession?.id ?? session.accessToken.hashCode.toString(),
        empresaId: profile.empresaId,
        usuarioId: user.id,
        tecnicoId: profile.tecnicoId,
        papel: profile.papel,
        accessTokenRef: SecureTokenStore.accessTokenRef,
        refreshTokenRef: SecureTokenStore.refreshTokenRef,
        endpointRef: previousSession?.endpointRef ?? 'active',
        expiresAt: expiresAt,
        lastValidatedAt: now,
        offlineAccessUntil: now.add(const Duration(days: 7)),
        createdAt: previousSession?.createdAt ?? now,
        updatedAt: now,
      );
    });
  }

  Future<_TecnicoProfile> _fetchTecnicoProfile({
    required SupabaseClient client,
    required User user,
  }) async {
    final profile = await client
        .from('tecnicos')
        .select('id, empresa_id, papel')
        .eq('user_id', user.id)
        .eq('ativo', true)
        .maybeSingle();

    if (profile == null) {
      throw const RemoteAuthException(
        'Conta remota autenticada, mas nao vinculada a uma empresa TechReport.',
      );
    }

    final empresaId = profile['empresa_id'];
    final tecnicoId = profile['id'];
    final papel = profile['papel'];

    if (empresaId is! String ||
        empresaId.isEmpty ||
        tecnicoId is! String ||
        tecnicoId.isEmpty ||
        papel is! String ||
        papel.isEmpty) {
      throw const RemoteAuthException(
        'Cadastro remoto incompleto para este usuario.',
      );
    }

    return _TecnicoProfile(
      empresaId: empresaId,
      tecnicoId: tecnicoId,
      papel: _toPapel(papel),
    );
  }

  SessaoRemotaPapel _toPapel(String value) {
    switch (value) {
      case 'gerente':
        return SessaoRemotaPapel.gerente;
      case 'tecnico':
        return SessaoRemotaPapel.tecnico;
      default:
        return SessaoRemotaPapel.tecnico;
    }
  }
}

class _TecnicoProfile {
  const _TecnicoProfile({
    required this.empresaId,
    required this.tecnicoId,
    required this.papel,
  });

  final String empresaId;
  final String tecnicoId;
  final SessaoRemotaPapel papel;
}
