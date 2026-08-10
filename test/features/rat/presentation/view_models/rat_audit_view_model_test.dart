import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/rat/domain/entities/rat_audit_event.dart';
import 'package:techreport/features/rat/domain/repositories/rat_audit_repository.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_audit_view_model.dart';

void main() {
  test('resposta online vazia e o unico estado empty', () async {
    final repository = _FakeAuditRepository()..pages.add(_page([]));
    final viewModel = RatAuditViewModel(repository: repository, ratId: 'rat-1');

    await viewModel.load();

    expect(viewModel.status, RatAuditViewStatus.empty);
    expect(viewModel.failure, isNull);
  });

  test(
    'offline e acesso negado permanecem estados distintos sem eventos',
    () async {
      for (final testCase in <(Object, RatAuditViewStatus)>[
        (const RatAuditOfflineException(), RatAuditViewStatus.offline),
        (
          const RatAuditAccessDeniedException(),
          RatAuditViewStatus.accessDenied,
        ),
      ]) {
        final repository = _FakeAuditRepository()..errors.add(testCase.$1);
        final viewModel = RatAuditViewModel(
          repository: repository,
          ratId: 'rat-1',
        );

        await viewModel.load();

        expect(viewModel.status, testCase.$2);
        expect(viewModel.events, isEmpty);
      }
    },
  );

  test('paginacao appenda sem duplicar e preserva conteúdo em falha', () async {
    final cursor = RatAuditCursor(
      editedAt: DateTime.utc(2026, 8, 9),
      id: 'evento-1',
    );
    final repository = _FakeAuditRepository()
      ..pages.add(_page([_event('evento-1')], cursor: cursor))
      ..pages.add(
        _page([_event('evento-1'), _event('evento-0')], cursor: cursor),
      )
      ..errors.add(const RatAuditLoadException());
    final viewModel = RatAuditViewModel(repository: repository, ratId: 'rat-1');

    await viewModel.load();
    await viewModel.loadMore();
    expect(viewModel.events.map((event) => event.id), ['evento-1', 'evento-0']);

    await viewModel.loadMore();
    expect(viewModel.status, RatAuditViewStatus.content);
    expect(viewModel.failure, RatAuditFailure.load);
    expect(viewModel.events, hasLength(2));
  });

  test(
    'refresh offline remove timeline para nao simular cache canonico',
    () async {
      final repository = _FakeAuditRepository()
        ..pages.add(_page([_event('evento-1')]))
        ..errors.add(const RatAuditOfflineException());
      final viewModel = RatAuditViewModel(
        repository: repository,
        ratId: 'rat-1',
      );

      await viewModel.load();
      await viewModel.refresh();

      expect(viewModel.status, RatAuditViewStatus.offline);
      expect(viewModel.events, isEmpty);
    },
  );

  test('ignora carregamento inicial concorrente', () async {
    final pending = Completer<RatAuditPage>();
    final repository = _FakeAuditRepository()..pending = pending.future;
    final viewModel = RatAuditViewModel(repository: repository, ratId: 'rat-1');

    final first = viewModel.load();
    await viewModel.load();
    expect(repository.calls, 1);
    pending.complete(_page([_event('evento-1')]));
    await first;
    expect(viewModel.status, RatAuditViewStatus.content);
  });
}

class _FakeAuditRepository implements RatAuditRepository {
  final List<RatAuditPage> pages = [];
  final List<Object> errors = [];
  Future<RatAuditPage>? pending;
  int calls = 0;

  @override
  Future<RatAuditPage> listForRat({
    required String ratId,
    RatAuditCursor? cursor,
    int limit = 20,
  }) async {
    calls++;
    final pendingCall = pending;
    if (pendingCall != null) return pendingCall;
    if (pages.isNotEmpty) return pages.removeAt(0);
    if (errors.isNotEmpty) throw errors.removeAt(0);
    return _page([]);
  }
}

RatAuditPage _page(List<RatAuditEvent> events, {RatAuditCursor? cursor}) =>
    RatAuditPage(events: events, nextCursor: cursor);

RatAuditEvent _event(String id) => RatAuditEvent(
  id: id,
  ratId: 'rat-1',
  type: RatAuditEventType.updated,
  actorUserId: 'user-1',
  actorName: 'Maria',
  editedAt: DateTime.utc(2026, 8, 9),
  diffs: const [],
);
