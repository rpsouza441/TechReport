import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:techreport/features/company_auth/domain/entities/remote_endpoint_config.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';

class LocalRemoteEndpointRepository implements RemoteEndpointRepository {
  LocalRemoteEndpointRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _activeEndpointKey = 'company_auth.active_endpoint';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clearActiveEndpoint() async {
    final endpoint = await getActiveEndpoint();

    if (endpoint != null) {
      await _storage.delete(key: endpoint.supabasePublicKeyRef);
    }

    await _storage.delete(key: _activeEndpointKey);
  }

  @override
  Future<RemoteEndpointConfig?> getActiveEndpoint() async {
    final rawEndpoint = await _storage.read(key: _activeEndpointKey);
    if (rawEndpoint == null) {
      return null;
    }

    final json = jsonDecode(rawEndpoint) as Map<String, dynamic>;

    return RemoteEndpointConfig(
      id: json['id'] as String,
      nome: json['nome'] as String,
      supabaseUrl: json['supabaseUrl'] as String,
      supabasePublicKeyRef: json['supabasePublicKeyRef'] as String,
      tipo: json['tipo'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Future<void> saveActiveEndpoint({
    required RemoteEndpointConfig endpoint,
    required String supabasePublicKey,
  }) async {
    await _storage.write(
      key: endpoint.supabasePublicKeyRef,
      value: supabasePublicKey,
    );

    await _storage.write(
      key: _activeEndpointKey,
      value: jsonEncode({
        'id': endpoint.id,
        'nome': endpoint.nome,
        'supabaseUrl': endpoint.supabaseUrl,
        'supabasePublicKeyRef': endpoint.supabasePublicKeyRef,
        'tipo': endpoint.tipo,
        'isActive': endpoint.isActive,
        'createdAt': endpoint.createdAt.toIso8601String(),
        'updatedAt': endpoint.updatedAt.toIso8601String(),
      }),
    );
  }

  @override
  Future<String?> readSupabasePublicKey(RemoteEndpointConfig endpoint) {
    return _storage.read(key: endpoint.supabasePublicKeyRef);
  }
}
