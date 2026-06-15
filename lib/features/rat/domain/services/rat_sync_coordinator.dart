import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';

/// Centraliza a logica de sync apos operacoes de save, delete e assinatura
/// do RAT, evitando duplicacao nos pontos de chamada em [RatFormViewModel].
///
/// Cada metodo segue a mesma sequencia:
///
/// 1. Enfileirar a operacao (upsert ou delete)
/// 2. Processar a fila de sync
///
/// A chamada a [ProcessSyncQueue] nao usa [Future.catchError] nem `unawaited`;
/// erros de sync sao propagados para que o caller possa tratar — a RAT local
/// ja esta salva, entao o retry automatico da fila cobrira falhas transitrias.
class RatSyncCoordinator {
  RatSyncCoordinator({
    required EnqueueRatSync enqueueRatSync,
    required EnqueueAssinaturaSync enqueueAssinaturaSync,
    required ProcessSyncQueue processSyncQueue,
  }) : _enqueueRatSync = enqueueRatSync,
       _enqueueAssinaturaSync = enqueueAssinaturaSync,
       _processSyncQueue = processSyncQueue;

  final EnqueueRatSync _enqueueRatSync;
  final EnqueueAssinaturaSync _enqueueAssinaturaSync;
  final ProcessSyncQueue _processSyncQueue;

  /// Enfileia o RAT para sync e processa a fila.
  Future<void> syncAfterSave({
    required Rat rat,
    required String empresaId,
    required String usuarioId,
  }) async {
    await _enqueueRatSync.upsert(rat);
    await _processSyncQueue.call(empresaId: empresaId, usuarioId: usuarioId);
  }

  /// Enfileira o delete do RAT para sync e processa a fila.
  Future<void> syncAfterDelete({
    required Rat rat,
    required String empresaId,
    required String usuarioId,
  }) async {
    await _enqueueRatSync.delete(rat);
    await _processSyncQueue.call(empresaId: empresaId, usuarioId: usuarioId);
  }

  /// Enfileira a assinatura para sync e processa a fila.
  Future<void> syncAfterSignature({
    required Assinatura assinatura,
    required String empresaId,
    required String usuarioId,
    required String ratId,
  }) async {
    await _enqueueAssinaturaSync.upsert(
      assinatura,
      empresaId: empresaId,
      usuarioId: usuarioId,
      ratId: ratId,
    );
    await _processSyncQueue.call(empresaId: empresaId, usuarioId: usuarioId);
  }
}