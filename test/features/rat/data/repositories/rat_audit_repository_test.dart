import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/rat/data/repositories/supabase_rat_audit_repository.dart';
import 'package:techreport/features/rat/domain/entities/rat_audit_event.dart';
import 'package:techreport/features/rat/domain/repositories/rat_audit_repository.dart';

void main() {
  group('contrato imutavel de auditoria', () {
    test('cursor e diff possuem igualdade por valor', () {
      final editedAt = DateTime.parse('2026-08-09T15:30:00Z');

      expect(
        RatAuditCursor(editedAt: editedAt, id: 'evento-2'),
        RatAuditCursor(editedAt: editedAt, id: 'evento-2'),
      );
      expect(
        const RatAuditFieldDiff(
          field: 'cliente_nome',
          label: 'Cliente',
          beforeValue: 'Cliente antigo',
          afterValue: 'Cliente novo',
        ),
        const RatAuditFieldDiff(
          field: 'cliente_nome',
          label: 'Cliente',
          beforeValue: 'Cliente antigo',
          afterValue: 'Cliente novo',
        ),
      );
    });

    test('pagina e eventos nao permitem alterar colecoes recebidas', () {
      final event = RatAuditEvent(
        id: 'evento-1',
        ratId: 'rat-1',
        type: RatAuditEventType.updated,
        actorUserId: 'user-1',
        actorName: 'Maria Gestora',
        editedAt: DateTime.parse('2026-08-09T15:30:00Z'),
        diffs: const [
          RatAuditFieldDiff(
            field: 'descricao',
            label: 'Descrição',
            beforeValue: 'Antes',
            afterValue: 'Depois',
          ),
        ],
      );
      final page = RatAuditPage(events: [event], nextCursor: null);

      expect(() => event.diffs.add(event.diffs.single), throwsUnsupportedError);
      expect(() => page.events.clear(), throwsUnsupportedError);
    });
  });

  group('SupabaseRatAuditRepository', () {
    test('faz apenas SELECT remoto, escopado por RAT e newest-first', () async {
      final client = _RecordingHttpClient(
        responseBody: jsonEncode([
          _row(
            id: 'evento-3',
            editedAt: '2026-08-09T15:33:00Z',
            eventType: 'restored',
          ),
          _row(
            id: 'evento-2',
            editedAt: '2026-08-09T15:32:00Z',
            eventType: 'trashed',
          ),
          _row(
            id: 'evento-1',
            editedAt: '2026-08-09T15:31:00Z',
            eventType: 'created',
          ),
        ]),
      );
      final repository = _repository(client);

      final page = await repository.listForRat(ratId: 'rat-1', limit: 2);

      expect(page.events.map((event) => event.id), ['evento-3', 'evento-2']);
      expect(page.events.map((event) => event.type), [
        RatAuditEventType.restored,
        RatAuditEventType.trashed,
      ]);
      expect(
        page.nextCursor,
        RatAuditCursor(
          editedAt: DateTime.parse('2026-08-09T15:32:00Z'),
          id: 'evento-2',
        ),
      );

      expect(client.requests, hasLength(1));
      final request = client.requests.single;
      expect(request.method, 'GET', reason: 'auditoria e somente leitura');
      expect(request.url.path, endsWith('/rest/v1/rat_audit_log'));
      expect(request.url.queryParameters['rat_id'], 'eq.rat-1');
      expect(request.url.queryParameters['order'], 'edited_at.desc,id.desc');
      expect(request.url.queryParameters['limit'], '3');
      expect(
        client.requests.where((item) => item.method != 'GET'),
        isEmpty,
        reason: 'o cliente nunca cria, altera ou apaga auditoria',
      );
    });

    test('usa cursor composto editedAt/id sem offset', () async {
      final client = _RecordingHttpClient(responseBody: '[]');
      final repository = _repository(client);
      final cursor = RatAuditCursor(
        editedAt: DateTime.parse('2026-08-09T15:32:00Z'),
        id: 'evento-2',
      );

      await repository.listForRat(ratId: 'rat-1', cursor: cursor, limit: 20);

      final query = client.requests.single.url.queryParameters;
      expect(query, isNot(contains('offset')));
      expect(query['order'], 'edited_at.desc,id.desc');
      expect(query['or'], contains('edited_at.lt.2026-08-09T15:32:00.000Z'));
      expect(query['or'], contains('edited_at.eq.2026-08-09T15:32:00.000Z'));
      expect(query['or'], contains('id.lt.evento-2'));
    });

    test(
      'mapeia snapshot do ator, eventos e diffs para produto em PT-BR',
      () async {
        final client = _RecordingHttpClient(
          responseBody: jsonEncode([
            _row(
              id: 'evento-1',
              editedAt: '2026-08-09T15:31:00Z',
              eventType: 'updated',
              actorName: 'Maria Gestora',
              changes: {
                'cliente_nome': {'old': 'Antigo', 'new': 'Novo'},
                'descricao': {'old': null, 'new': 'Atendimento concluido'},
                'status': {'old': 'draft', 'new': 'finalizado'},
                'updated_at': {'old': 'a', 'new': 'b'},
                'server_updated_at': {'old': 'a', 'new': 'b'},
                'sincronizado_em': {'old': null, 'new': 'agora'},
                'origem_dispositivo': {'old': 'a', 'new': 'b'},
                'versao': {'old': 1, 'new': 2},
                'ultimo_alterador_user_id': {'old': 'a', 'new': 'b'},
                'ultima_alteracao_em': {'old': 'a', 'new': 'b'},
                'created_at': {'old': 'a', 'new': 'b'},
                'deletado': {'old': false, 'new': true},
              },
            ),
          ]),
        );

        final event = (await _repository(
          client,
        ).listForRat(ratId: 'rat-1')).events.single;

        expect(event.actorName, 'Maria Gestora');
        expect(event.type, RatAuditEventType.updated);
        expect(event.diffs.map((diff) => diff.label), [
          'Cliente',
          'Descrição',
          'Status',
        ]);
        expect(event.diffs[1].beforeValue, 'Não informado');
        expect(event.diffs[2].beforeValue, 'Rascunho');
        expect(event.diffs[2].afterValue, 'Finalizada');
        expect(
          event.diffs.map((diff) => diff.field),
          isNot(
            containsAll(<String>[
              'updated_at',
              'server_updated_at',
              'sincronizado_em',
              'origem_dispositivo',
              'versao',
              'ultimo_alterador_user_id',
              'ultima_alteracao_em',
              'created_at',
              'deletado',
            ]),
          ),
        );
      },
    );

    test('usa fallback legado de UUID sem consultar perfis', () async {
      final client = _RecordingHttpClient(
        responseBody: jsonEncode([
          _row(
            id: 'evento-legado',
            editedAt: '2026-08-09T15:30:00Z',
            eventType: null,
            actorName: null,
            actorUserId: '12345678-abcd-4000-8000-123456789abc',
          ),
        ]),
      );

      final event = (await _repository(
        client,
      ).listForRat(ratId: 'rat-1')).events.single;

      expect(event.type, RatAuditEventType.updated);
      expect(event.actorName, 'Usuário · 12345678');
      expect(client.requests, hasLength(1));
      expect(client.requests.single.url.path, isNot(contains('profiles')));
      expect(client.requests.single.url.path, isNot(contains('tecnicos')));
    });

    test('403 permanece acesso negado, nunca pagina vazia', () async {
      final repository = _repository(
        _RecordingHttpClient(
          statusCode: 403,
          responseBody: '{"message":"permission denied"}',
        ),
      );

      expect(
        repository.listForRat(ratId: 'rat-negada'),
        throwsA(isA<RatAuditAccessDeniedException>()),
      );
    });

    test('falha de conectividade permanece offline', () async {
      final repository = _repository(
        _RecordingHttpClient(error: const SocketException('sem conexao')),
      );

      expect(
        repository.listForRat(ratId: 'rat-1'),
        throwsA(isA<RatAuditOfflineException>()),
      );
    });

    test(
      'resposta malformada ou erro do servidor permanece falha de carga',
      () async {
        final malformed = _repository(
          _RecordingHttpClient(responseBody: '[{"id":42}]'),
        );
        final serverError = _repository(
          _RecordingHttpClient(statusCode: 500, responseBody: '{}'),
        );

        expect(
          malformed.listForRat(ratId: 'rat-1'),
          throwsA(isA<RatAuditLoadException>()),
        );
        expect(
          serverError.listForRat(ratId: 'rat-1'),
          throwsA(isA<RatAuditLoadException>()),
        );
      },
    );
  });
}

SupabaseRatAuditRepository _repository(_RecordingHttpClient httpClient) {
  final client = SupabaseClient(
    'https://project.supabase.co',
    'public-anon-key',
    httpClient: httpClient,
  );
  return SupabaseRatAuditRepository(
    clientFactory: _FakeSupabaseClientFactory(client),
  );
}

Map<String, Object?> _row({
  required String id,
  required String editedAt,
  required String? eventType,
  String? actorName = 'Maria Gestora',
  String actorUserId = '12345678-abcd-4000-8000-123456789abc',
  Map<String, Object?> changes = const {},
}) {
  return {
    'id': id,
    'rat_id': 'rat-1',
    'user_id': actorUserId,
    'actor_name': actorName,
    'event_type': eventType,
    'edited_at': editedAt,
    'changes': changes,
  };
}

class _FakeSupabaseClientFactory implements SupabaseClientFactory {
  _FakeSupabaseClientFactory(this.client);

  final SupabaseClient client;

  @override
  Future<SupabaseClient?> tryCreateAuthenticatedClient() async => client;

  @override
  Future<SupabaseClient?> tryCreateClient() async => client;
}

class _RecordedRequest {
  const _RecordedRequest({required this.method, required this.url});

  final String method;
  final Uri url;
}

class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient({
    this.responseBody = '[]',
    this.statusCode = 200,
    this.error,
  });

  final String responseBody;
  final int statusCode;
  final Object? error;
  final List<_RecordedRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(_RecordedRequest(method: request.method, url: request.url));
    if (error case final Object failure) {
      throw failure;
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(responseBody)),
      statusCode,
      headers: const {'content-type': 'application/json'},
      request: request,
    );
  }
}
