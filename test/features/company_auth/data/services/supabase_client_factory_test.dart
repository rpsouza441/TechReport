import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/company_auth/data/services/secure_token_store.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/company_auth/domain/entities/remote_endpoint_config.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';

class _MemoryPkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

class _EndpointRepository implements RemoteEndpointRepository {
  final endpoint = RemoteEndpointConfig(
    id: 'server-dev',
    nome: 'Servidor dev',
    supabaseUrl: 'https://supabase.example.test',
    supabasePublicKeyRef: 'key-ref',
    tipo: 'supabase',
    isActive: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  @override
  Future<RemoteEndpointConfig?> getActiveEndpoint() async => endpoint;

  @override
  Future<String?> readSupabasePublicKey(RemoteEndpointConfig endpoint) async {
    return 'public-key';
  }

  @override
  Future<void> clearActiveEndpoint() => throw UnimplementedError();

  @override
  Future<void> saveActiveEndpoint({
    required RemoteEndpointConfig endpoint,
    required String supabasePublicKey,
  }) => throw UnimplementedError();
}

class _TokenStore implements SecureTokenStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('signUp under PKCE stores a verifier before calling GoTrue', () async {
    final pkceStorage = _MemoryPkceStorage();
    var requestCount = 0;
    final httpClient = MockClient((request) async {
      requestCount++;
      return http.Response(
        jsonEncode({'msg': 'test response'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    });
    final factory = SupabaseClientFactory(
      endpointRepository: _EndpointRepository(),
      tokenStore: _TokenStore(),
      pkceStorageFactory: (endpointId) {
        expect(endpointId, 'server-dev');
        return pkceStorage;
      },
      httpClient: httpClient,
    );

    final client = await factory.tryCreateClient();

    expect(client, isNotNull);
    await expectLater(
      client!.auth.signUp(email: 'convidado@example.com', password: '123123'),
      throwsA(isA<AuthException>()),
    );
    expect(requestCount, 1);
    expect(pkceStorage.values, isNotEmpty);
    expect(
      pkceStorage.values.keys,
      contains('supabase.auth.token-code-verifier'),
    );
  });
}
