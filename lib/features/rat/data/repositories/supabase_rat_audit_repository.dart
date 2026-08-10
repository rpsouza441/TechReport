import 'dart:async';
import 'dart:io';

import 'package:postgrest/postgrest.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/rat/domain/entities/rat_audit_event.dart';
import 'package:techreport/features/rat/domain/repositories/rat_audit_repository.dart';

class SupabaseRatAuditRepository implements RatAuditRepository {
  SupabaseRatAuditRepository({required SupabaseClientFactory clientFactory})
    : _clientFactory = clientFactory;

  final SupabaseClientFactory _clientFactory;

  static const _fieldLabels = <String, String>{
    'numero': 'Número',
    'cliente_nome': 'Cliente',
    'responsavel_recebimento': 'Responsável pelo recebimento',
    'responsavel_documento': 'Documento do responsável',
    'data_visita': 'Data da visita',
    'horario_inicio_atendimento': 'Início do atendimento',
    'horario_termino_atendimento': 'Término do atendimento',
    'descricao': 'Descrição',
    'equipamento_movimento_tipo': 'Movimentação do equipamento',
    'equipamento_descricao': 'Equipamento',
    'equipamento_observacao': 'Observação do equipamento',
    'status': 'Status',
    'reaberta_para_correcao_em': 'Reaberta para correção',
    'motivo_reabertura': 'Motivo da reabertura',
    'assinatura_invalidada_em': 'Assinatura invalidada',
  };

  @override
  Future<RatAuditPage> listForRat({
    required String ratId,
    RatAuditCursor? cursor,
    int limit = 20,
  }) async {
    if (ratId.isEmpty || limit <= 0) {
      throw const RatAuditLoadException('Consulta de auditoria invalida.');
    }

    try {
      final client = await _clientFactory.tryCreateAuthenticatedClient();
      if (client == null) {
        throw const RatAuditOfflineException();
      }

      var query = client.from('rat_audit_log').select().eq('rat_id', ratId);
      if (cursor != null) {
        final editedAt = cursor.editedAt.toUtc().toIso8601String();
        query = query.or(
          'edited_at.lt.$editedAt,and(edited_at.eq.$editedAt,id.lt.${cursor.id})',
        );
      }

      final ordered = query.copyWithUrl(
        query.overrideSearchParams('order', 'edited_at.desc,id.desc'),
      );
      final rows = await ordered.limit(limit + 1);
      final events = rows.map<RatAuditEvent>(_toEvent).toList();
      final hasMore = events.length > limit;
      final visible = hasMore ? events.take(limit).toList() : events;
      final last = visible.isEmpty ? null : visible.last;

      return RatAuditPage(
        events: visible,
        nextCursor: hasMore && last != null
            ? RatAuditCursor(editedAt: last.editedAt, id: last.id)
            : null,
      );
    } on RatAuditException {
      rethrow;
    } on SocketException catch (error) {
      throw RatAuditOfflineException(
        'Historico da RAT indisponivel sem conexao.',
        error,
      );
    } on TimeoutException catch (error) {
      throw RatAuditOfflineException(
        'Historico da RAT indisponivel sem conexao.',
        error,
      );
    } on PostgrestException catch (error) {
      final denied =
          error.code == '403' ||
          error.code == '42501' ||
          error.message.toLowerCase().contains('permission denied');
      if (denied) {
        throw RatAuditAccessDeniedException(
          'Acesso negado ao historico da RAT.',
          error,
        );
      }
      throw RatAuditLoadException(
        'Nao foi possivel carregar o historico da RAT.',
        error,
      );
    } catch (error) {
      throw RatAuditLoadException(
        'Nao foi possivel carregar o historico da RAT.',
        error,
      );
    }
  }

  RatAuditEvent _toEvent(Map<String, dynamic> row) {
    final id = row['id'];
    final ratId = row['rat_id'];
    final actorUserId = row['user_id'];
    final editedAt = row['edited_at'];
    if (id is! String ||
        ratId is! String ||
        actorUserId is! String ||
        editedAt is! String) {
      throw const FormatException('Evento de auditoria malformado.');
    }

    final actorSnapshot = row['actor_name'];
    final actorName = actorSnapshot is String && actorSnapshot.trim().isNotEmpty
        ? actorSnapshot.trim()
        : 'Usuário · ${_abbreviate(actorUserId)}';
    final changes = row['changes'];

    return RatAuditEvent(
      id: id,
      ratId: ratId,
      type: _eventType(row['event_type']),
      actorUserId: actorUserId,
      actorName: actorName,
      editedAt: DateTime.parse(editedAt),
      diffs: changes is Map<String, dynamic> ? _mapDiffs(changes) : const [],
    );
  }

  List<RatAuditFieldDiff> _mapDiffs(Map<String, dynamic> changes) {
    final diffs = <RatAuditFieldDiff>[];
    for (final entry in changes.entries) {
      final label = _fieldLabels[entry.key];
      final change = entry.value;
      if (label == null || change is! Map) continue;
      diffs.add(
        RatAuditFieldDiff(
          field: entry.key,
          label: label,
          beforeValue: _displayValue(entry.key, change['old']),
          afterValue: _displayValue(entry.key, change['new']),
        ),
      );
    }
    return diffs;
  }

  RatAuditEventType _eventType(Object? value) {
    return switch (value) {
      'created' => RatAuditEventType.created,
      'trashed' => RatAuditEventType.trashed,
      'restored' => RatAuditEventType.restored,
      _ => RatAuditEventType.updated,
    };
  }

  String _displayValue(String field, Object? value) {
    if (value == null || value == '') return 'Não informado';
    if (value is bool) return value ? 'Sim' : 'Não';
    if (field == 'status') {
      return switch (value) {
        'draft' => 'Rascunho',
        'finalizado' => 'Finalizada',
        'enviado' => 'Enviada',
        'arquivado' => 'Arquivada',
        _ => value.toString(),
      };
    }
    if (field == 'equipamento_movimento_tipo') {
      return switch (value) {
        'nenhum' => 'Nenhuma movimentação',
        'retirada_para_reparo' => 'Retirada para reparo',
        'entrega_pos_reparo' => 'Entrega após reparo',
        'entrega_pos_compra' => 'Entrega após compra',
        _ => value.toString(),
      };
    }
    return value.toString();
  }

  String _abbreviate(String value) {
    return value.length <= 8 ? value : value.substring(0, 8);
  }
}
