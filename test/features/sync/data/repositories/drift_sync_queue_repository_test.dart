import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/sync/data/repositories/drift_sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/shared/infra/database/tech_report_local_database.dart';

void main() {
  late TechReportLocalDatabase database;
  late DriftSyncQueueRepository sut;

  setUp(() {
    database = TechReportLocalDatabase(NativeDatabase.memory());
    sut = DriftSyncQueueRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('replacePendingPayload', () {
    test(
      'atualiza pending preservando createdAt e alterando updatedAt',
      () async {
        final createdAt = DateTime(2026, 6, 26, 8);
        final oldUpdatedAt = DateTime(2026, 6, 26, 8, 10);
        final newUpdatedAt = DateTime(2026, 6, 26, 9);
        await sut.enqueue(
          _item(
            payload: '{"old":true}',
            createdAt: createdAt,
            updatedAt: oldUpdatedAt,
          ),
        );

        final replaced = await sut.replacePendingPayload(
          empresaId: 'emp-1',
          usuarioId: 'user-1',
          entityType: SyncEntityType.rat,
          entityId: 'rat-1',
          operation: SyncOperation.upsert,
          payload: '{"new":true}',
          updatedAt: newUpdatedAt,
        );

        expect(replaced, isTrue);
        final item = (await sut.listForSession(
          empresaId: 'emp-1',
          usuarioId: 'user-1',
        )).single;
        expect(item.payload, '{"new":true}');
        expect(item.status, SyncItemStatus.pending);
        expect(item.createdAt, createdAt);
        expect(item.updatedAt, newUpdatedAt);
      },
    );

    test('renova failed para pending e limpa retry', () async {
      await sut.enqueue(
        _item(
          status: SyncItemStatus.failed,
          attempts: 3,
          lastError: 'timeout',
          nextAttemptAt: DateTime(2026, 6, 26, 12),
        ),
      );

      final replaced = await sut.replacePendingPayload(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: 'rat-1',
        operation: SyncOperation.upsert,
        payload: '{"retry":true}',
        updatedAt: DateTime(2026, 6, 26, 9),
      );

      expect(replaced, isTrue);
      final item = (await sut.listForSession(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
      )).single;
      expect(item.payload, '{"retry":true}');
      expect(item.status, SyncItemStatus.pending);
      expect(item.attempts, 0);
      expect(item.lastError, isNull);
      expect(item.nextAttemptAt, isNull);
    });

    test('nao atualiza processing', () async {
      await sut.enqueue(_item(status: SyncItemStatus.processing));

      final replaced = await sut.replacePendingPayload(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: 'rat-1',
        operation: SyncOperation.upsert,
        payload: '{"new":true}',
        updatedAt: DateTime(2026, 6, 26, 9),
      );

      expect(replaced, isFalse);
      final item = (await sut.listForSession(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
      )).single;
      expect(item.payload, '{"id":"rat-1"}');
      expect(item.status, SyncItemStatus.processing);
    });

    test('nao cruza empresa nem entityType', () async {
      await sut.enqueue(_item(id: 'sync-emp', empresaId: 'emp-2'));
      await sut.enqueue(
        _item(
          id: 'sync-type',
          entityType: SyncEntityType.assinatura,
          entityId: 'rat-1',
        ),
      );

      final replaced = await sut.replacePendingPayload(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: 'rat-1',
        operation: SyncOperation.upsert,
        payload: '{"new":true}',
        updatedAt: DateTime(2026, 6, 26, 9),
      );

      expect(replaced, isFalse);
    });

    test('cross-user/cross-operation: transfere escopo e operacao', () async {
      // Item pendente de outro usuario, operacao delete.
      await sut.enqueue(
        _item(
          id: 'sync-outro',
          usuarioId: 'user-2',
          operation: SyncOperation.delete,
        ),
      );

      final replaced = await sut.replacePendingPayload(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
        entityType: SyncEntityType.rat,
        entityId: 'rat-1',
        operation: SyncOperation.upsert,
        payload: '{"new":true}',
        updatedAt: DateTime(2026, 6, 26, 9),
      );

      expect(replaced, isTrue);
      // Escopo transferido para user-1; operacao virou upsert.
      final items = await sut.listForSession(
        empresaId: 'emp-1',
        usuarioId: 'user-1',
      );
      expect(items, hasLength(1));
      expect(items.single.payload, '{"new":true}');
      expect(items.single.operation, SyncOperation.upsert);
    });
  });
}

SyncItem _item({
  String id = 'sync-1',
  String empresaId = 'emp-1',
  String usuarioId = 'user-1',
  SyncEntityType entityType = SyncEntityType.rat,
  String entityId = 'rat-1',
  SyncOperation operation = SyncOperation.upsert,
  String payload = '{"id":"rat-1"}',
  SyncItemStatus status = SyncItemStatus.pending,
  int attempts = 0,
  String? lastError,
  DateTime? nextAttemptAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 6, 26, 8);
  return SyncItem(
    id: id,
    empresaId: empresaId,
    usuarioId: usuarioId,
    entityType: entityType,
    entityId: entityId,
    operation: operation,
    payload: payload,
    status: status,
    attempts: attempts,
    lastError: lastError,
    nextAttemptAt: nextAttemptAt,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}
