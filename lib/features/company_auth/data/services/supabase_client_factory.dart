import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:techreport/features/company_auth/data/services/flutter_secure_pkce_storage.dart';
import 'package:techreport/features/company_auth/data/services/secure_token_store.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';

typedef PkceStorageFactory = GotrueAsyncStorage Function(String endpointId);

class SupabaseClientFactory {
  SupabaseClientFactory({
    required RemoteEndpointRepository endpointRepository,
    required SecureTokenStore tokenStore,
    PkceStorageFactory? pkceStorageFactory,
    http.Client? httpClient,
  }) : _endpointRepository = endpointRepository,
       _tokenStore = tokenStore,
       _pkceStorageFactory =
           pkceStorageFactory ??
           ((endpointId) => FlutterSecurePkceStorage(endpointId: endpointId)),
       _httpClient = httpClient;

  final RemoteEndpointRepository _endpointRepository;
  final SecureTokenStore _tokenStore;
  final PkceStorageFactory _pkceStorageFactory;
  final http.Client? _httpClient;

  Future<SupabaseClient?> tryCreateClient() async {
    return _createClient();
  }

  Future<SupabaseClient?> tryCreateAuthenticatedClient() async {
    final client = await _createClient();
    if (client == null) {
      return null;
    }

    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final response = await client.auth.setSession(refreshToken);
    final session = response.session;

    if (session == null) {
      return null;
    }

    final newRefreshToken = session.refreshToken;
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
      await _tokenStore.saveTokens(
        accessToken: session.accessToken,
        refreshToken: newRefreshToken,
      );
    }

    return client;
  }

  Future<SupabaseClient?> _createClient() async {
    final endpoint = await _endpointRepository.getActiveEndpoint();
    if (endpoint == null || !endpoint.isActive) {
      return null;
    }

    final publicKey = await _endpointRepository.readSupabasePublicKey(endpoint);

    if (publicKey == null || publicKey.trim().isEmpty) {
      return null;
    }

    return SupabaseClient(
      endpoint.supabaseUrl,
      publicKey,
      authOptions: AuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        pkceAsyncStorage: _pkceStorageFactory(endpoint.id),
      ),
      httpClient: _httpClient,
    );
  }
}
