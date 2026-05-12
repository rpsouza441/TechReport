import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';

class LocalRemoteSessionRepository implements RemoteSessionRepository {
  LocalRemoteSessionRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'company_auth.remote_session';

  final FlutterSecureStorage _storage;

  @override
  Future<SessaoRemota?> getSession() async {
    final rawSession = await _storage.read(key: _sessionKey);
    if (rawSession == null) {
      return null;
    }

    final json = jsonDecode(rawSession) as Map<String, dynamic>;

    return SessaoRemota(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      usuarioId: json['usuarioId'] as String,
      tecnicoId: json['tecnicoId'] as String,
      papel: SessaoRemotaPapel.values.byName(
        (json['papel'] as String?) ?? SessaoRemotaPapel.tecnico.name,
      ),
      accessTokenRef: json['accessTokenRef'] as String,
      refreshTokenRef: json['refreshTokenRef'] as String,
      endpointRef: json['endpointRef'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      lastValidatedAt: DateTime.parse(json['lastValidatedAt'] as String),
      offlineAccessUntil: DateTime.parse(json['offlineAccessUntil'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Future<void> saveSession(SessaoRemota session) async {
    await _storage.write(key: _sessionKey, value: _toJson(session));
  }

  @override
  Future<void> updateSession(SessaoRemota session) async {
    await saveSession(session);
  }

  @override
  Future<void> deleteSession() async {
    await _storage.delete(key: _sessionKey);
  }

  @override
  Future<bool> hasSession() async {
    return await getSession() != null;
  }

  String _toJson(SessaoRemota session) {
    return jsonEncode({
      'id': session.id,
      'empresaId': session.empresaId,
      'usuarioId': session.usuarioId,
      'tecnicoId': session.tecnicoId,
      'papel': session.papel.name,
      'accessTokenRef': session.accessTokenRef,
      'refreshTokenRef': session.refreshTokenRef,
      'endpointRef': session.endpointRef,
      'expiresAt': session.expiresAt.toIso8601String(),
      'lastValidatedAt': session.lastValidatedAt.toIso8601String(),
      'offlineAccessUntil': session.offlineAccessUntil.toIso8601String(),
      'createdAt': session.createdAt.toIso8601String(),
      'updatedAt': session.updatedAt.toIso8601String(),
    });
  }
}
