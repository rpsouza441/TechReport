import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../signature/domain/entities/assinatura.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/sync_queue_repository.dart';

class EnqueueAssinaturaSync {
  const EnqueueAssinaturaSync({
    required SyncQueueRepository queueRepository,
    Uuid uuid = const Uuid(),
  }) : _queueRepository = queueRepository,
       _uuid = uuid;

  final SyncQueueRepository _queueRepository;
  final Uuid _uuid;

  Future<void> upsert(Assinatura assinatura, {
    required String empresaId,
    required String usuarioId,
    required String ratId,
  }) async {
    final now = DateTime.now();

    await _queueRepository.enqueue(
      SyncItem(
        id: _uuid.v4(),
        empresaId: empresaId,
        usuarioId: usuarioId,
        entityType: SyncEntityType.assinatura,
        entityId: assinatura.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode({
          'empresaId': empresaId,
          'ratId': ratId,
          'assinaturaId': assinatura.id,
          'sizeBytes': assinatura.sizeBytes,
          'mimeType': assinatura.mimeType ?? 'image/png',
          'deletedAt': null,
        }),
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> delete(Assinatura assinatura, {
    required String empresaId,
    required String usuarioId,
    required String ratId,
  }) async {
    final now = DateTime.now();

    await _queueRepository.enqueue(
      SyncItem(
        id: _uuid.v4(),
        empresaId: empresaId,
        usuarioId: usuarioId,
        entityType: SyncEntityType.assinatura,
        entityId: assinatura.id,
        operation: SyncOperation.delete,
        payload: jsonEncode({
          'empresaId': empresaId,
          'ratId': ratId,
          'assinaturaId': assinatura.id,
          'deletedAt': DateTime.now().toIso8601String(),
        }),
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}