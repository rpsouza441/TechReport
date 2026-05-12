enum SyncEntityType { rat }

enum SyncOperation { upsert, delete }

enum SyncItemStatus { pending, processing, synced, failed }

class SyncItem {
  const SyncItem({
    required this.id,
    required this.empresaId,
    required this.usuarioId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.status,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
    this.nextAttemptAt,
  });

  final String id;
  final String empresaId;
  final String usuarioId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final String payload;
  final SyncItemStatus status;
  final int attempts;
  final String? lastError;
  final DateTime? nextAttemptAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get canProcess {
    final next = nextAttemptAt;
    return status == SyncItemStatus.pending &&
        (next == null || !DateTime.now().isBefore(next));
  }
}
