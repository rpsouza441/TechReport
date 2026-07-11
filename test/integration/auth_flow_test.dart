import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/company_auth/data/repositories/supabase_auth_repository.dart';
import 'package:techreport/features/company_auth/data/services/secure_token_store.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/company_auth/domain/entities/remote_endpoint_config.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';

class _MemoryTokenStore implements SecureTokenStore {
  String? accessToken;
  String? refreshToken;
  PendingCompanyInvite? pendingInvite;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<void> savePendingInvite({
    required String email,
    required String codigoConvite,
  }) async {
    pendingInvite = PendingCompanyInvite(
      email: email,
      codigoConvite: codigoConvite,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<PendingCompanyInvite?> readPendingInvite() async => pendingInvite;

  @override
  Future<void> clearPendingInvite() async {
    pendingInvite = null;
  }
}

class _MemorySessionRepository implements RemoteSessionRepository {
  SessaoRemota? session;

  @override
  Future<SessaoRemota?> getSession() async => session;

  @override
  Future<bool> hasSession() async => session != null;

  @override
  Future<void> saveSession(SessaoRemota session) async {
    this.session = session;
  }

  @override
  Future<void> updateSession(SessaoRemota session) async {
    this.session = session;
  }

  @override
  Future<void> deleteSession() async {
    session = null;
  }
}

class _NoEndpointRepository implements RemoteEndpointRepository {
  @override
  Future<RemoteEndpointConfig?> getActiveEndpoint() async => null;

  @override
  Future<String?> readSupabasePublicKey(RemoteEndpointConfig endpoint) async =>
      null;

  @override
  Future<void> saveActiveEndpoint({
    required RemoteEndpointConfig endpoint,
    required String supabasePublicKey,
  }) async {}

  @override
  Future<void> clearActiveEndpoint() async {}
}

SessaoRemota _session({String email = 'test@example.com'}) {
  final now = DateTime.now();
  return SessaoRemota(
    id: 'session-1',
    empresaId: 'empresa-1',
    usuarioId: 'usuario-1',
    tecnicoId: 'tecnico-1',
    email: email,
    nome: 'Tecnico',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: SessaoRemotaPapelEmpresa.tecnico,
    accessTokenRef: SecureTokenStore.accessTokenRef,
    refreshTokenRef: SecureTokenStore.refreshTokenRef,
    endpointRef: 'active',
    expiresAt: now.add(const Duration(hours: 1)),
    lastValidatedAt: now,
    offlineAccessUntil: now.add(const Duration(days: 7)),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MemoryTokenStore tokenStore;
  late _MemorySessionRepository sessionRepository;
  late SupabaseAuthRepository repository;

  setUp(() {
    tokenStore = _MemoryTokenStore();
    sessionRepository = _MemorySessionRepository();
    repository = SupabaseAuthRepository(
      clientFactory: SupabaseClientFactory(
        endpointRepository: _NoEndpointRepository(),
        tokenStore: tokenStore,
      ),
      tokenStore: tokenStore,
      remoteSessionRepository: sessionRepository,
    );
  });

  group('persisted authentication state', () {
    test('currentSession returns the saved session', () async {
      final expected = _session();
      await sessionRepository.saveSession(expected);

      expect(await repository.currentSession(), expected);
      expect(await sessionRepository.hasSession(), isTrue);
    });

    test('currentSession returns null without persisted state', () async {
      expect(await repository.currentSession(), isNull);
      expect(await sessionRepository.hasSession(), isFalse);
    });

    test('session update replaces the persisted identity', () async {
      await sessionRepository.saveSession(_session());
      await sessionRepository.updateSession(_session(email: 'new@example.com'));

      expect((await repository.currentSession())?.email, 'new@example.com');
    });

    test('session deletion removes persisted authentication state', () async {
      await sessionRepository.saveSession(_session());
      await sessionRepository.deleteSession();

      expect(await repository.currentSession(), isNull);
    });
  });

  group('secure token lifecycle', () {
    test('tokens are saved and cleared together', () async {
      await tokenStore.saveTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      );

      expect(await tokenStore.readAccessToken(), 'access-token');
      expect(await tokenStore.readRefreshToken(), 'refresh-token');

      await tokenStore.clearTokens();

      expect(await tokenStore.readAccessToken(), isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
    });

    test('pending invite is persisted and cleared independently', () async {
      await tokenStore.saveTokens(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      );
      await tokenStore.savePendingInvite(
        email: 'invite@example.com',
        codigoConvite: 'INVITE-123',
      );

      final invite = await tokenStore.readPendingInvite();
      expect(invite?.email, 'invite@example.com');
      expect(invite?.codigoConvite, 'INVITE-123');

      await tokenStore.clearPendingInvite();

      expect(await tokenStore.readPendingInvite(), isNull);
      expect(await tokenStore.readAccessToken(), 'access-token');
    });
  });
}
