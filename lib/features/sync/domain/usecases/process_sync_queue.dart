import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';

class ProcessSyncQueue {
  const ProcessSyncQueue({
    required SyncQueueRepository queueRepository,
    required RemoteRatRepository remoteRatRepository,
  }) : _queueRepository = queueRepository,
       _remoteRatRepository = remoteRatRepository;

  final SyncQueueRepository _queueRepository;
  final RemoteRatRepository _remoteRatRepository;

  Future<void> call({
    required String empresaId,
    required String usuarioId,
    bool retryFailed = false,
  }) async {
    final items = await _queueRepository.listPending(
      empresaId: empresaId,
      usuarioId: usuarioId,
      includeFailed: retryFailed,
    );

    for (final item in items) {
      await _queueRepository.markProcessing(item.id);

      try {
        switch (item.operation) {
          case SyncOperation.upsert:
            await _remoteRatRepository.upsertFromPayload(item.payload);
          case SyncOperation.delete:
            await _remoteRatRepository.softDeleteFromPayload(item.payload);
        }

        await _queueRepository.markSynced(item.id);
      } catch (e) {
        await _queueRepository.markFailed(
          id: item.id,
          errorMessage: e.toString(),
          nextAttemptAt: DateTime.now().add(const Duration(minutes: 5)),
        );
      }
    }
  }
}
