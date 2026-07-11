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

  /// Tenta marcar o item como 'processing' apenas se o status atual for
  /// 'pending'. Retorna true se o lock foi adquirido, false se o item ja
  /// estava sendo processado por outro ou nao existia.
  /// Implementa lock otimista para evitar processamento concorrente do mesmo
  /// item.
  Future<bool> tryMarkProcessing(String id);

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

  /// Substitui o item pendente/falho de uma entidade pelo estado mais recente.
  ///
  /// Busca por `empresaId + entityType + entityId` (**cross-user** e
  /// **cross-operation**): garante no maximo uma operacao pendente por entidade.
  /// Ao encontrar, atualiza `payload`, `operation` e transfere o escopo de
  /// processamento para `usuarioId` (sessao atual). Retorna true quando
  /// encontra um item atualizavel. Itens em `processing` nao sao alterados,
  /// pois podem estar em envio no momento da chamada.
  Future<bool> replacePendingPayload({
    required String empresaId,
    required String usuarioId,
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required String payload,
    required DateTime updatedAt,
    bool resetFailure = true,
  });

  /// Retorna true se ja existe um item pendente (status = pending ou
  /// processing) para a entityType + entityId dada, dentro da empresa.
  /// Usado para deduplicar itens de sync antes de enfileirar.
  Future<bool> hasPendingItem({
    required String empresaId,
    required String usuarioId,
    required SyncEntityType entityType,
    required String entityId,
  });
}
