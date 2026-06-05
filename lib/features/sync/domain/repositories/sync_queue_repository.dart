import '../entities/sync_item.dart';

abstract class SyncQueueRepository {
  Future<void> enqueue(SyncItem item);

  Future<List<SyncItem>> listPending({
    required String empresaId,
    required String usuarioId,
    bool includeFailed = false,
    int limit = 20,
  });

  Future<int> countPending({
    required String empresaId,
    required String usuarioId,
  });

  Future<void> markProcessing(String id);

  Future<void> markSynced(String id);

  Future<void> markFailed({
    required String id,
    required String errorMessage,
    required DateTime nextAttemptAt,
  });

  Future<List<SyncItem>> listForSession({
    required String empresaId,
    required String usuarioId,
    int limit = 50,
  });

  /// Retorna true se já existe um item pendente (status = pending ou
  /// processing) para a entityType + entityId givena, dentro da empresa.
  /// Usado para deduplicar itens de sync antes de enfileirar.
  Future<bool> hasPendingItem({
    required String empresaId,
    required String usuarioId,
    required SyncEntityType entityType,
    required String entityId,
  });
}
