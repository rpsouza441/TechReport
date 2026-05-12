import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/entities/rat_remote_snapshot.dart';
import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';

class SupabaseRemoteRatRepository implements RemoteRatRepository {
  SupabaseRemoteRatRepository({required SupabaseClientFactory clientFactory})
    : _clientFactory = clientFactory;

  final SupabaseClientFactory _clientFactory;

  @override
  Future<void> upsertFromPayload(String payload) async {
    final client = await _requireClient();
    final data = _decodePayload(payload);

    await client.from('rats').upsert(data);
  }

  @override
  Future<void> softDeleteFromPayload(String payload) async {
    final client = await _requireClient();
    final data = _decodePayload(payload);
    final id = data['id'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Payload de RAT sem id.');
    }

    await client.from('rats').update({'deletado': true}).eq('id', id);
  }

  @override
  Future<List<RatRemoteSnapshot>> fetchUpdatedSince({
    required String empresaId,
    required DateTime? since,
  }) async {
    final client = await _requireClient();

    final query = client.from('rats').select().eq('empresa_id', empresaId);

    final rows = since == null
        ? await query.order('server_updated_at')
        : await query
              .gt('server_updated_at', since.toIso8601String())
              .order('server_updated_at');

    return rows.map<RatRemoteSnapshot>(_toSnapshot).toList();
  }

  RatRemoteSnapshot _toSnapshot(Map<String, dynamic> row) {
    final serverUpdatedAt = DateTime.parse(row['server_updated_at'] as String);

    return RatRemoteSnapshot(
      rat: Rat(
        id: row['id'] as String,
        authorId: row['tecnico_id'] as String,
        empresaId: row['empresa_id'] as String,
        usuarioId: row['criado_por_user_id'] as String,
        tecnicoId: row['tecnico_id'] as String,
        ownerType: RatOwnerType.companyTecnico,
        numero: row['numero'] as String,
        clienteNome: row['cliente_nome'] as String,
        descricao: row['descricao'] as String,
        status: RatStatus.values.byName(row['status'] as String),
        syncStatus: RatSyncStatus.synced,
        createdAt: DateTime.parse(row['criado_em_dispositivo'] as String),
        updatedAt: serverUpdatedAt,
        deletedAt: (row['deletado'] as bool) ? serverUpdatedAt : null,
      ),
      serverUpdatedAt: serverUpdatedAt,
    );
  }

  Future<SupabaseClient> _requireClient() async {
    final client = await _clientFactory.tryCreateAuthenticatedClient();

    if (client == null) {
      throw StateError('Sessao remota nao restaurada.');
    }

    return client;
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final decoded = jsonDecode(payload);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Payload de RAT invalido.');
    }

    return decoded;
  }
}
