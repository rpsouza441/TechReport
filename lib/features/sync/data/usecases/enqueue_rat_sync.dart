import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../rat/data/dtos/rat_remote_dto.dart';
import '../../../rat/domain/entities/rat.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/sync_queue_repository.dart';

class EnqueueRatSync {
  const EnqueueRatSync({
    required SyncQueueRepository queueRepository,
    Uuid uuid = const Uuid(),
  }) : _queueRepository = queueRepository,
       _uuid = uuid;

  final SyncQueueRepository _queueRepository;
  final Uuid _uuid;

  Future<void> upsert(Rat rat) async {
    final context = _requireCompanyContext(rat);
    final now = DateTime.now();

    final dto = RatRemoteDto(
      id: rat.id,
      empresaId: context.empresaId,
      tecnicoId: context.tecnicoId,
      criadoPorUserId: context.usuarioId,
      numero: rat.numero,
      clienteNome: rat.clienteNome,
      descricao: rat.descricao,
      status: rat.status.name,
      deletado: rat.deletedAt != null,
      criadoEmDispositivo: rat.createdAt,
    );

    await _queueRepository.enqueue(
      SyncItem(
        id: _uuid.v4(),
        empresaId: context.empresaId,
        usuarioId: context.usuarioId,
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: SyncOperation.upsert,
        payload: jsonEncode(dto.toJson()),
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> delete(Rat rat) async {
    final context = _requireCompanyContext(rat);
    final now = DateTime.now();

    final dto = RatRemoteDto(
      id: rat.id,
      empresaId: context.empresaId,
      tecnicoId: context.tecnicoId,
      criadoPorUserId: context.usuarioId,
      numero: rat.numero,
      clienteNome: rat.clienteNome,
      descricao: rat.descricao,
      status: rat.status.name,
      deletado: true,
      criadoEmDispositivo: rat.createdAt,
    );

    await _queueRepository.enqueue(
      SyncItem(
        id: _uuid.v4(),
        empresaId: context.empresaId,
        usuarioId: context.usuarioId,
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: SyncOperation.delete,
        payload: jsonEncode(dto.toJson()),
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  _CompanyRatContext _requireCompanyContext(Rat rat) {
    if (rat.ownerType != RatOwnerType.companyTecnico) {
      throw StateError('RAT local nao deve gerar item de sync.');
    }

    final empresaId = rat.empresaId;
    final usuarioId = rat.usuarioId;
    final tecnicoId = rat.tecnicoId;

    if (empresaId == null ||
        empresaId.isEmpty ||
        usuarioId == null ||
        usuarioId.isEmpty ||
        tecnicoId == null ||
        tecnicoId.isEmpty) {
      throw StateError('RAT company sem vinculo remoto completo.');
    }

    return _CompanyRatContext(
      empresaId: empresaId,
      usuarioId: usuarioId,
      tecnicoId: tecnicoId,
    );
  }
}

class _CompanyRatContext {
  const _CompanyRatContext({
    required this.empresaId,
    required this.usuarioId,
    required this.tecnicoId,
  });

  final String empresaId;
  final String usuarioId;
  final String tecnicoId;
}
