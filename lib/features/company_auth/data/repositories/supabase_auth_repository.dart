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
      throw const RemoteAuthException('Sessão remota não foi retornada.');
    }

    final user = response.user;
    if (user == null) {
      throw const RemoteAuthException('Usuário remoto não foi retornado.');
    }

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const RemoteAuthException(
        'Refresh token remoto não foi retornado.',
      );
    }

    try {
      await _acceptPendingInviteIfAny(client: client, user: user);

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
    } catch (_) {
      await _clearRemoteState(client);
      rethrow;
    }
  }

  @override
  Future<SessaoRemota> signInWithInvite({
    required String email,
    required String password,
    required String codigoConvite,
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
      throw const RemoteAuthException('Sessão remota não foi retornada.');
    }

    final user = response.user;
    if (user == null) {
      throw const RemoteAuthException('Usuário remoto não foi retornado.');
    }

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const RemoteAuthException(
        'Refresh token remoto não foi retornado.',
      );
    }

    try {
      await _tokenStore.saveTokens(
        accessToken: session.accessToken,
        refreshToken: refreshToken,
      );

      try {
        await client.rpc(
          'accept_tecnico_convite',
          params: {'p_codigo': codigoConvite.trim()},
        );
      } on PostgrestException catch (e) {
        if (!_isAlreadyLinkedMessage(e.message) &&
            !_isInviteAlreadyConsumedMessage(e.message)) {
          throw RemoteAuthException(e.message);
        }
      }
      await _tokenStore.clearPendingInvite();

      final remoteSession = await buildRemoteSession(
        client: client,
        session: session,
        user: user,
      );

      await _remoteSessionRepository.saveSession(remoteSession);

      return remoteSession;
    } catch (_) {
      await _clearRemoteState(client);
      rethrow;
    }
  }

  @override
  Future<SessaoRemota> signUpWithInvite({
    required String email,
    required String password,
    required String codigoConvite,
  }) async {
    final client = await requireClient();

    try {
      await client.rpc(
        'validate_tecnico_convite',
        params: {'p_email': email.trim(), 'p_codigo': codigoConvite.trim()},
      );
    } on PostgrestException catch (e) {
      throw RemoteAuthException(e.message);
    }

    final AuthResponse response;
    try {
      response = await client.auth.signUp(
        email: email.trim(),
        password: password,
      );
    } on AuthApiException catch (e) {
      throw mapAuthException(e);
    }

    final session = response.session;
    final user = response.user;

    if (session == null || user == null) {
      await _tokenStore.savePendingInvite(
        email: email,
        codigoConvite: codigoConvite,
      );
      throw const RemoteAuthException(
        'Conta criada. Confirme o e-mail e depois entre por "Aceitar convite".',
      );
    }

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const RemoteAuthException(
        'Refresh token remoto nÃ£o foi retornado.',
      );
    }

    try {
      await _tokenStore.saveTokens(
        accessToken: session.accessToken,
        refreshToken: refreshToken,
      );

      try {
        await client.rpc(
          'accept_tecnico_convite',
          params: {'p_codigo': codigoConvite.trim()},
        );
      } on PostgrestException catch (e) {
        if (!_isAlreadyLinkedMessage(e.message) &&
            !_isInviteAlreadyConsumedMessage(e.message)) {
          throw RemoteAuthException(e.message);
        }
      }
      await _tokenStore.clearPendingInvite();

      final remoteSession = await buildRemoteSession(
        client: client,
        session: session,
        user: user,
      );

      await _remoteSessionRepository.saveSession(remoteSession);

      return remoteSession;
    } catch (_) {
      await _clearRemoteState(client);
      rethrow;
    }
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

    final AuthResponse response;
    try {
      response = await client.auth.setSession(refreshToken);
    } on AuthApiException {
      await _remoteSessionRepository.deleteSession();
      await _tokenStore.clearTokens();
      return null;
    }

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

    final AuthResponse response;
    try {
      response = await client.auth.setSession(savedRefreshToken);
    } on AuthApiException {
      await _remoteSessionRepository.deleteSession();
      await _tokenStore.clearTokens();
      return null;
    }

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
      throw const RemoteAuthException('Servidor remoto não configurado.');
    }

    return client;
  }

  Future<void> _clearRemoteState(SupabaseClient client) async {
    try {
      await client.auth.signOut();
    } catch (_) {
      // Best effort: local state is the important part here.
    }

    await _tokenStore.clearTokens();
    await _remoteSessionRepository.deleteSession();
  }

  Future<void> _acceptPendingInviteIfAny({
    required SupabaseClient client,
    required User user,
  }) async {
    final pendingInvite = await _tokenStore.readPendingInvite();
    if (pendingInvite == null) {
      return;
    }

    final userEmail = user.email?.trim().toLowerCase();
    if (userEmail == null || userEmail != pendingInvite.email) {
      return;
    }

    final age = DateTime.now().difference(pendingInvite.createdAt);
    if (age > const Duration(days: 7)) {
      await _tokenStore.clearPendingInvite();
      return;
    }

    try {
      await client.rpc(
        'accept_tecnico_convite',
        params: {'p_codigo': pendingInvite.codigoConvite},
      );
      await _tokenStore.clearPendingInvite();
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('expirado') ||
          message.contains('cancel') ||
          message.contains('invalido') ||
          message.contains('inválido') ||
          _isAlreadyLinkedMessage(message) ||
          _isInviteAlreadyConsumedMessage(message)) {
        await _tokenStore.clearPendingInvite();
        return;
      }
      rethrow;
    }
  }

  bool _isAlreadyLinkedMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('ja vinculado') ||
        normalized.contains('já vinculado') ||
        normalized.contains('vinculado a uma empresa');
  }

  bool _isInviteAlreadyConsumedMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('convite nao esta pendente') ||
        normalized.contains('convite não está pendente') ||
        normalized.contains('convite ja aceito') ||
        normalized.contains('convite já aceito');
  }

  RemoteAuthException mapAuthException(AuthApiException exception) {
    if (exception.code == 'invalid_credentials') {
      return const RemoteAuthException('E-mail ou senha inválidos.');
    }

    return const RemoteAuthException(
      'Não foi possível entrar. Confira os dados e tente novamente.',
    );
  }

  Future<SessaoRemota> buildRemoteSession({
    required SupabaseClient client,
    required Session session,
    required User user,
    SessaoRemota? previousSession,
  }) async {
    final now = DateTime.now();
    final expiresAt = session.expiresAt == null
        ? now
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);

    final appAdmin = await _fetchAppAdminProfile(client: client, user: user);
    if (appAdmin != null) {
      return SessaoRemota(
        id: previousSession?.id ?? session.accessToken.hashCode.toString(),
        empresaId: null,
        usuarioId: user.id,
        tecnicoId: null,
        email: appAdmin.email,
        nome: appAdmin.nome,
        mustChangePassword: appAdmin.mustChangePassword,
        papelGlobal: SessaoRemotaPapelGlobal.appAdmin,
        papelEmpresa: null,
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

    final profile = await _fetchTecnicoProfile(client: client, user: user);

    return SessaoRemota(
      id: previousSession?.id ?? session.accessToken.hashCode.toString(),
      empresaId: profile.empresaId,
      usuarioId: user.id,
      tecnicoId: profile.tecnicoId,
      email: profile.email,
      nome: profile.nome,
      mustChangePassword: profile.mustChangePassword,
      papelGlobal: null,
      papelEmpresa: profile.papel,
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

  @override
  Future<void> changePassword(String newPassword) async {
    try {
      final client = await _clientFactory.tryCreateAuthenticatedClient();
      if (client == null) {
        throw const RemoteAuthException(
          'Sessão remota expirada. Entre novamente para trocar a senha.',
        );
      }

      await client.auth.updateUser(UserAttributes(password: newPassword));
    } on RemoteAuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw _mapChangePasswordException(e);
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('session')) {
        throw const RemoteAuthException(
          'Sessão remota expirada. Entre novamente para trocar a senha.',
        );
      }
      throw RemoteAuthException(e.message);
    }
  }

  RemoteAuthException _mapChangePasswordException(AuthApiException exception) {
    final message = exception.message.toLowerCase();
    if (message.contains('session')) {
      throw const RemoteAuthException(
        'Sessão remota expirada. Entre novamente para trocar a senha.',
      );
    }

    return const RemoteAuthException(
      'Não foi possível trocar a senha. Entre novamente e tente outra vez.',
    );
  }

  Future<_AppAdminProfile?> _fetchAppAdminProfile({
    required SupabaseClient client,
    required User user,
  }) async {
    final profile = await client
        .from('app_admins')
        .select('id, nome, email, must_change_password')
        .eq('user_id', user.id)
        .eq('ativo', true)
        .maybeSingle();

    if (profile == null) {
      return null;
    }

    return _AppAdminProfile(
      id: profile['id'] as String,
      nome: profile['nome'] as String?,
      email: profile['email'] as String? ?? user.email ?? '',
      mustChangePassword: profile['must_change_password'] as bool? ?? false,
    );
  }

  Future<_TecnicoProfile> _fetchTecnicoProfile({
    required SupabaseClient client,
    required User user,
  }) async {
    final profile = await client
        .from('tecnicos')
        .select(
          'id, empresa_id, nome, email, papel, ativo, must_change_password',
        )
        .eq('user_id', user.id)
        .order('ativo', ascending: false)
        .limit(1)
        .maybeSingle();

    if (profile == null) {
      throw const RemoteAuthException(
        'Conta remota autenticada, mas não vinculada a uma empresa TechReport.',
      );
    }

    final ativo = profile['ativo'];
    if (ativo is bool && !ativo) {
      throw const RemoteAuthException(
        'Conta remota autenticada, mas desativada nesta empresa. '
        'Fale com o administrador.',
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
        'Cadastro remoto incompleto para este usuário.',
      );
    }

    return _TecnicoProfile(
      empresaId: empresaId,
      tecnicoId: tecnicoId,
      nome: profile['nome'] as String?,
      email: profile['email'] as String? ?? user.email ?? '',
      papel: _toPapelEmpresa(papel),
      mustChangePassword: profile['must_change_password'] as bool? ?? false,
    );
  }

  SessaoRemotaPapelEmpresa _toPapelEmpresa(String value) {
    switch (value) {
      case 'admin_empresa':
        return SessaoRemotaPapelEmpresa.adminEmpresa;
      case 'gerente':
        return SessaoRemotaPapelEmpresa.gerente;
      case 'tecnico':
        return SessaoRemotaPapelEmpresa.tecnico;
      default:
        throw const RemoteAuthException('Papel remoto inválido.');
    }
  }
}

class _AppAdminProfile {
  const _AppAdminProfile({
    required this.id,
    required this.nome,
    required this.email,
    required this.mustChangePassword,
  });

  final String id;
  final String? nome;
  final String email;
  final bool mustChangePassword;
}

class _TecnicoProfile {
  const _TecnicoProfile({
    required this.empresaId,
    required this.tecnicoId,
    required this.nome,
    required this.email,
    required this.papel,
    required this.mustChangePassword,
  });

  final String empresaId;
  final String tecnicoId;
  final String? nome;
  final String email;
  final SessaoRemotaPapelEmpresa papel;
  final bool mustChangePassword;
}
