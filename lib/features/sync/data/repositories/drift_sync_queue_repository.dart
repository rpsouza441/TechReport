import 'package:drift/drift.dart';
import '../../../../shared/infra/database/tech_report_local_database.dart';
import '../../domain/entities/sync_item.dart' as domain;
import '../../domain/repositories/sync_queue_repository.dart';

class DriftSyncQueueRepository implements SyncQueueRepository {
  DriftSyncQueueRepository(this._database);

  final TechReportLocalDatabase _database;

  @override
  Future<void> enqueue(domain.SyncItem item) async {
    await _database
        .into(_database.syncQueueItems)
        .insertOnConflictUpdate(_toCompanion(item));
  }

  @override
  Future<List<domain.SyncItem>> listPending({
    required String empresaId,
    required String usuarioId,
    bool includeFailed = false,
    int limit = 20,
  }) async {
    final now = DateTime.now();

    final rows =
        await (_database.select(_database.syncQueueItems)
              ..where((tbl) {
                final statusFilter = includeFailed
                    ? tbl.status.equals(domain.SyncItemStatus.pending.name) |
                          tbl.status.equals(domain.SyncItemStatus.failed.name)
                    : tbl.status.equals(domain.SyncItemStatus.pending.name);

                final retryAtFilter = includeFailed
                    ? const Constant(true)
                    : tbl.nextAttemptAt.isNull() |
                          tbl.nextAttemptAt.isSmallerOrEqualValue(now);

                return tbl.empresaId.equals(empresaId) &
                    tbl.usuarioId.equals(usuarioId) &
                    statusFilter &
                    retryAtFilter;
              })
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])
              ..limit(limit))
            .get();

    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> markProcessing(String id) async {
    await (_database.update(
      _database.syncQueueItems,
    )..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueItemsCompanion(
        status: Value(domain.SyncItemStatus.processing.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> markSynced(String id) async {
    await (_database.update(
      _database.syncQueueItems,
    )..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueItemsCompanion(
        status: Value(domain.SyncItemStatus.synced.name),
        lastError: const Value<String?>(null),
        nextAttemptAt: const Value<DateTime?>(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> markFailed({
    required String id,
    required String errorMessage,
    required DateTime nextAttemptAt,
  }) async {
    final row = await (_database.select(
      _database.syncQueueItems,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    if (row == null) {
      return;
    }

    await (_database.update(
      _database.syncQueueItems,
    )..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueItemsCompanion(
        status: Value(domain.SyncItemStatus.failed.name),
        attempts: Value(row.attempts + 1),
        lastError: Value(errorMessage),
        nextAttemptAt: Value(nextAttemptAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  domain.SyncItem _toEntity(SyncQueueItem row) {
    return domain.SyncItem(
      id: row.id,
      empresaId: row.empresaId,
      usuarioId: row.usuarioId,
      entityType: _toEntityType(row.entityType),
      entityId: row.entityId,
      operation: _toOperation(row.operation),
      payload: row.payload,
      status: _toStatus(row.status),
      attempts: row.attempts,
      lastError: row.lastError,
      nextAttemptAt: row.nextAttemptAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  SyncQueueItemsCompanion _toCompanion(domain.SyncItem item) {
    return SyncQueueItemsCompanion(
      id: Value(item.id),
      empresaId: Value(item.empresaId),
      usuarioId: Value(item.usuarioId),
      entityType: Value(item.entityType.name),
      entityId: Value(item.entityId),
      operation: Value(item.operation.name),
      payload: Value(item.payload),
      status: Value(item.status.name),
      attempts: Value(item.attempts),
      lastError: Value(item.lastError),
      nextAttemptAt: Value(item.nextAttemptAt),
      createdAt: Value(item.createdAt),
      updatedAt: Value(item.updatedAt),
    );
  }

  domain.SyncEntityType _toEntityType(String value) {
    switch (value) {
      case 'rat':
        return domain.SyncEntityType.rat;
      default:
        throw ArgumentError('SyncEntityType invalido: $value');
    }
  }

  domain.SyncOperation _toOperation(String value) {
    switch (value) {
      case 'upsert':
        return domain.SyncOperation.upsert;
      case 'delete':
        return domain.SyncOperation.delete;
      default:
        throw ArgumentError('SyncOperation invalido: $value');
    }
  }

  domain.SyncItemStatus _toStatus(String value) {
    switch (value) {
      case 'pending':
        return domain.SyncItemStatus.pending;
      case 'processing':
        return domain.SyncItemStatus.processing;
      case 'synced':
        return domain.SyncItemStatus.synced;
      case 'failed':
        return domain.SyncItemStatus.failed;
      default:
        throw ArgumentError('SyncItemStatus invalido: $value');
    }
  }
}
