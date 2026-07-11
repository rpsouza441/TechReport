import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../rat/data/dtos/rat_remote_dto.dart';
import '../../../rat/domain/entities/rat.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/entities/sync_session_context.dart';
import '../../domain/repositories/sync_queue_repository.dart';

class EnqueueRatSync {
  const EnqueueRatSync({
    required SyncQueueRepository queueRepository,
    Uuid uuid = const Uuid(),
  }) : _queueRepository = queueRepository,
       _uuid = uuid;

  final SyncQueueRepository _queueRepository;
  final Uuid _uuid;

  Future<void> upsert(Rat rat, {required SyncSessionContext session}) async {
    await _enqueue(rat, session: session, operation: SyncOperation.upsert);
  }

  Future<void> delete(Rat rat, {required SyncSessionContext session}) async {
    await _enqueue(rat, session: session, operation: SyncOperation.delete);
  }

  Future<void> _enqueue(
    Rat rat, {
    required SyncSessionContext session,
    required SyncOperation operation,
  }) async {
    final context = _requireCompanyContext(rat);
    _validateSession(session: session, context: context);

    final now = DateTime.now();
    final payload = _buildPayload(
      rat,
      context: context,
      deletado: operation == SyncOperation.delete,
    );

    // RF-09: no maximo uma operacao pendente por RAT. Uma edicao posterior
    // (de qualquer usuario autorizado) assume o item existente, transferindo o
    // escopo de processamento para a sessao atual e gravando a operacao/payload
    // mais recentes.
    final replaced = await _queueRepository.replacePendingPayload(
      empresaId: session.empresaId,
      usuarioId: session.usuarioId,
      entityType: SyncEntityType.rat,
      entityId: rat.id,
      operation: operation,
      payload: payload,
      updatedAt: now,
    );
    if (replaced) return;

    await _queueRepository.enqueue(
      SyncItem(
        id: _uuid.v4(),
        empresaId: session.empresaId,
        usuarioId: session.usuarioId,
        entityType: SyncEntityType.rat,
        entityId: rat.id,
        operation: operation,
        payload: payload,
        status: SyncItemStatus.pending,
        attempts: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  String _buildPayload(
    Rat rat, {
    required _CompanyRatContext context,
    required bool deletado,
  }) {
    final dto = RatRemoteDto(
      id: rat.id,
      empresaId: context.empresaId,
      tecnicoId: context.tecnicoId,
      criadoPorUserId: context.usuarioId,
      numero: rat.numero,
      clienteNome: rat.clienteNome,
      responsavelRecebimento: rat.responsavelRecebimento,
      responsavelDocumento: rat.responsavelDocumento,
      dataVisita: rat.dataVisita,
      horarioInicioAtendimento: rat.horarioInicioAtendimento,
      horarioTerminoAtendimento: rat.horarioTerminoAtendimento,
      descricao: rat.descricao,
      equipamentoMovimentoTipo: rat.equipamentoMovimentoTipo,
      equipamentoDescricao: rat.equipamentoDescricao,
      equipamentoObservacao: rat.equipamentoObservacao,
      status: rat.status.name,
      deletado: deletado || rat.deletedAt != null,
      criadoEmDispositivo: rat.createdAt,
      ultimoAlteradorUserId: rat.ultimoAlteradorUserId,
      ultimaAlteracaoEm: rat.ultimaAlteracaoEm,
      reabertaParaCorrecaoEm: rat.reabertaParaCorrecaoEm,
      reabertaParaCorrecaoPorUserId: rat.reabertaParaCorrecaoPorUserId,
      motivoReabertura: rat.motivoReabertura,
      assinaturaInvalidadaEm: rat.assinaturaInvalidadaEm,
      assinaturaInvalidadaPorUserId: rat.assinaturaInvalidadaPorUserId,
    );
    return jsonEncode(dto.toJson());
  }

  /// RF-08: a operacao so e enfileirada se a sessao for valida e pertencer a
  /// mesma empresa da RAT. Em divergencia, falha sem tocar na fila.
  void _validateSession({
    required SyncSessionContext session,
    required _CompanyRatContext context,
  }) {
    if (!session.isValid) {
      throw StateError('Sessao de sync sem empresaId/usuarioId.');
    }
    if (session.empresaId != context.empresaId) {
      throw StateError(
        'Empresa da sessao difere da empresa da RAT; sync abortado.',
      );
    }
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
