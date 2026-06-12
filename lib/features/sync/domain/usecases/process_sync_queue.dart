import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/signature/domain/repositories/remote_assinatura_repository.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';
import 'package:techreport/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:techreport/features/sync/domain/usecases/process_assinatura_sync.dart';

class ProcessSyncQueue {
  ProcessSyncQueue({
    required SyncQueueRepository queueRepository,
    required RemoteRatRepository remoteRatRepository,
    required RatRepository ratRepository,
    required AssinaturaRepository assinaturaRepository,
    required RemoteAssinaturaRepository remoteAssinaturaRepository,
  }) : _queueRepository = queueRepository,
       _remoteRatRepository = remoteRatRepository,
       _ratRepository = ratRepository,
       _processAssinaturaSync = ProcessAssinaturaSync(
         assinaturaRepository: assinaturaRepository,
         remoteAssinaturaRepository: remoteAssinaturaRepository,
       );

  final SyncQueueRepository _queueRepository;
  final RemoteRatRepository _remoteRatRepository;
  final RatRepository _ratRepository;
  final ProcessAssinaturaSync _processAssinaturaSync;

  static const int maxAttempts = 5;

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
      if (item.attempts >= maxAttempts) {
        await _queueRepository.markFailed(
          id: item.id,
          errorMessage: 'Limite de tentativas excedido',
          nextAttemptAt: DateTime.now().add(const Duration(days: 30)),
        );
        continue;
      }

      final locked = await _queueRepository.tryMarkProcessing(item.id);
      if (!locked) continue; // já está sendo processado por outro

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
        await _markRatSynced(item);
      case SyncOperation.delete:
        await _remoteRatRepository.softDeleteFromPayload(item.payload);
    }
  }

  Future<void> _markRatSynced(SyncItem item) async {
    try {
      final rat = await _ratRepository.getById(item.entityId);
      if (rat != null) {
        final synced = rat.copyWith(
          syncStatus: RatSyncStatus.synced,
        );
        await _ratRepository.save(synced);
      }
    } catch (_) {
      // RAT local pode não existir (ex.: deletada entre sync e leitura).
      // Não bloqueia o sync — a RAT remota já foi atualizada.
    }
  }
}
