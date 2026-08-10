import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/usecases/restore_rat.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/entities/sync_session_context.dart';
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
enum RatRestoreSyncResult { localCompleted, remoteCompleted, queued }

class RatSyncCoordinator {
  RatSyncCoordinator({
    required EnqueueRatSync enqueueRatSync,
    required EnqueueAssinaturaSync enqueueAssinaturaSync,
    required ProcessSyncQueue processSyncQueue,
    RestoreRat? restoreRat,
  }) : _enqueueRatSync = enqueueRatSync,
       _enqueueAssinaturaSync = enqueueAssinaturaSync,
       _processSyncQueue = processSyncQueue,
       _restoreRat = restoreRat;

  final EnqueueRatSync _enqueueRatSync;
  final EnqueueAssinaturaSync _enqueueAssinaturaSync;
  final ProcessSyncQueue _processSyncQueue;
  final RestoreRat? _restoreRat;

  Future<RatRestoreSyncResult> restore({
    required Rat rat,
    required SessaoRemota? session,
  }) async {
    final restoreRat = _restoreRat;
    if (restoreRat == null) {
      throw StateError('RestoreRat nao configurado no coordenador.');
    }

    final restored = await restoreRat(ratId: rat.id, session: session);
    if (session == null) {
      return RatRestoreSyncResult.localCompleted;
    }

    final empresaId = session.empresaId;
    if (!session.hasCompanyContext || session.isAppAdmin || empresaId == null) {
      throw StateError('Sessao remota invalida para restaurar RAT.');
    }

    await _enqueueRatSync.restore(
      restored,
      session: SyncSessionContext(
        empresaId: empresaId,
        usuarioId: session.usuarioId,
      ),
    );
    final completed = await _processSyncQueue.call(
      empresaId: empresaId,
      usuarioId: session.usuarioId,
    );

    return completed
        ? RatRestoreSyncResult.remoteCompleted
        : RatRestoreSyncResult.queued;
  }

  /// Enfileia o RAT para sync e processa a fila.
  Future<void> syncAfterSave({
    required Rat rat,
    required String empresaId,
    required String usuarioId,
  }) async {
    await _enqueueRatSync.upsert(
      rat,
      session: SyncSessionContext(empresaId: empresaId, usuarioId: usuarioId),
    );
    await _processSyncQueue.call(empresaId: empresaId, usuarioId: usuarioId);
  }

  /// Enfileira o delete do RAT para sync e processa a fila.
  Future<void> syncAfterDelete({
    required Rat rat,
    required String empresaId,
    required String usuarioId,
  }) async {
    await _enqueueRatSync.delete(
      rat,
      session: SyncSessionContext(empresaId: empresaId, usuarioId: usuarioId),
    );
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
