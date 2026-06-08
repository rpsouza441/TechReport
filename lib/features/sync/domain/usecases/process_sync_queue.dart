import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/signature/domain/repositories/remote_assinatura_repository.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/usecases/process_assinatura_sync.dart';

class ProcessSyncQueue {
  ProcessSyncQueue({
    required SyncQueueRepository queueRepository,
    required RemoteRatRepository remoteRatRepository,
    required AssinaturaRepository assinaturaRepository,
    required RemoteAssinaturaRepository remoteAssinaturaRepository,
  }) : _queueRepository = queueRepository,
       _remoteRatRepository = remoteRatRepository,
       _processAssinaturaSync = ProcessAssinaturaSync(
         assinaturaRepository: assinaturaRepository,
         remoteAssinaturaRepository: remoteAssinaturaRepository,
       );

  final SyncQueueRepository _queueRepository;
  final RemoteRatRepository _remoteRatRepository;
  final ProcessAssinaturaSync _processAssinaturaSync;

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
        switch (item.entityType) {
          case SyncEntityType.rat:
            await _processRat(item);
          case SyncEntityType.assinatura:
            await _processAssinaturaSync(item);
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

  Future<void> _processRat(SyncItem item) async {
    switch (item.operation) {
      case SyncOperation.upsert:
        await _remoteRatRepository.upsertFromPayload(item.payload);
      case SyncOperation.delete:
        await _remoteRatRepository.softDeleteFromPayload(item.payload);
    }
  }
}
