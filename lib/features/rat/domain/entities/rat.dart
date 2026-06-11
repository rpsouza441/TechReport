enum RatStatus { draft, finalizado, enviado, arquivado }

enum RatSyncStatus { localOnly, pendingSync, synced, syncError }

enum RatOwnerType { localTecnico, companyTecnico }

enum EquipamentoMovimentoTipo {
  nenhum,
  retiradaParaReparo,
  entregaPosReparo,
  entregaPosCompra,
}

class Rat {
  const Rat({
    required this.id,
    required this.authorId,
    this.empresaId,
    this.usuarioId,
    this.tecnicoId,
    required this.ownerType,
    required this.numero,
    required this.clienteNome,
    this.responsavelRecebimento,
    this.responsavelDocumento,
    this.dataVisita,
    this.horarioInicioAtendimento,
    this.horarioTerminoAtendimento,
    required this.descricao,
    this.equipamentoMovimentoTipo,
    this.equipamentoDescricao,
    this.equipamentoObservacao,
    required this.status,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.ultimoAlteradorUserId,
    this.ultimaAlteracaoEm,
    this.reabertaParaCorrecaoEm,
    this.reabertaParaCorrecaoPorUserId,
    this.motivoReabertura,
    this.assinaturaInvalidadaEm,
    this.assinaturaInvalidadaPorUserId,
  });

  final String id;
  final String authorId;
  final String? empresaId;
  final String? usuarioId;
  final String? tecnicoId;
  final RatOwnerType ownerType;
  final String numero;
  final String clienteNome;
  final String? responsavelRecebimento;
  final String? responsavelDocumento;
  final DateTime? dataVisita;
  final String? horarioInicioAtendimento;
  final String? horarioTerminoAtendimento;
  final String descricao;
  final EquipamentoMovimentoTipo? equipamentoMovimentoTipo;
  final String? equipamentoDescricao;
  final String? equipamentoObservacao;
  final RatStatus status;
  final RatSyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? ultimoAlteradorUserId;
  final DateTime? ultimaAlteracaoEm;
  final DateTime? reabertaParaCorrecaoEm;
  final String? reabertaParaCorrecaoPorUserId;
  final String? motivoReabertura;
  final DateTime? assinaturaInvalidadaEm;
  final String? assinaturaInvalidadaPorUserId;

  bool get isDraft => status == RatStatus.draft;

  bool get isFinalizado => status == RatStatus.finalizado;

  bool get isArquivado => status == RatStatus.arquivado;

  bool get isEnviado => status == RatStatus.enviado;

  bool get isReabertaParaCorrecao => reabertaParaCorrecaoEm != null;

  bool get hasAssinaturaInvalidada => assinaturaInvalidadaEm != null;

  bool get isDeleted => deletedAt != null;

  Rat copyWith({
    String? id,
    String? authorId,
    String? empresaId,
    String? usuarioId,
    String? tecnicoId,
    RatOwnerType? ownerType,
    String? numero,
    String? clienteNome,
    Object? responsavelRecebimento = _sentinel,
    Object? responsavelDocumento = _sentinel,
    Object? dataVisita = _sentinel,
    Object? horarioInicioAtendimento = _sentinel,
    Object? horarioTerminoAtendimento = _sentinel,
    String? descricao,
    Object? equipamentoMovimentoTipo = _sentinel,
    Object? equipamentoDescricao = _sentinel,
    Object? equipamentoObservacao = _sentinel,
    RatStatus? status,
    RatSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _sentinel,
    Object? ultimoAlteradorUserId = _sentinel,
    Object? ultimaAlteracaoEm = _sentinel,
    Object? reabertaParaCorrecaoEm = _sentinel,
    Object? reabertaParaCorrecaoPorUserId = _sentinel,
    Object? motivoReabertura = _sentinel,
    Object? assinaturaInvalidadaEm = _sentinel,
    Object? assinaturaInvalidadaPorUserId = _sentinel,
  }) {
    return Rat(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      empresaId: empresaId ?? this.empresaId,
      usuarioId: usuarioId ?? this.usuarioId,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      ownerType: ownerType ?? this.ownerType,
      numero: numero ?? this.numero,
      clienteNome: clienteNome ?? this.clienteNome,
      responsavelRecebimento: responsavelRecebimento == _sentinel
          ? this.responsavelRecebimento
          : responsavelRecebimento as String?,
      responsavelDocumento: responsavelDocumento == _sentinel
          ? this.responsavelDocumento
          : responsavelDocumento as String?,
      dataVisita: dataVisita == _sentinel
          ? this.dataVisita
          : dataVisita as DateTime?,
      horarioInicioAtendimento: horarioInicioAtendimento == _sentinel
          ? this.horarioInicioAtendimento
          : horarioInicioAtendimento as String?,
      horarioTerminoAtendimento: horarioTerminoAtendimento == _sentinel
          ? this.horarioTerminoAtendimento
          : horarioTerminoAtendimento as String?,
      descricao: descricao ?? this.descricao,
      equipamentoMovimentoTipo: equipamentoMovimentoTipo == _sentinel
          ? this.equipamentoMovimentoTipo
          : equipamentoMovimentoTipo as EquipamentoMovimentoTipo?,
      equipamentoDescricao: equipamentoDescricao == _sentinel
          ? this.equipamentoDescricao
          : equipamentoDescricao as String?,
      equipamentoObservacao: equipamentoObservacao == _sentinel
          ? this.equipamentoObservacao
          : equipamentoObservacao as String?,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt == _sentinel
          ? this.deletedAt
          : deletedAt as DateTime?,
      ultimoAlteradorUserId: ultimoAlteradorUserId == _sentinel
          ? this.ultimoAlteradorUserId
          : ultimoAlteradorUserId as String?,
      ultimaAlteracaoEm: ultimaAlteracaoEm == _sentinel
          ? this.ultimaAlteracaoEm
          : ultimaAlteracaoEm as DateTime?,
      reabertaParaCorrecaoEm: reabertaParaCorrecaoEm == _sentinel
          ? this.reabertaParaCorrecaoEm
          : reabertaParaCorrecaoEm as DateTime?,
      reabertaParaCorrecaoPorUserId: reabertaParaCorrecaoPorUserId == _sentinel
          ? this.reabertaParaCorrecaoPorUserId
          : reabertaParaCorrecaoPorUserId as String?,
      motivoReabertura: motivoReabertura == _sentinel
          ? this.motivoReabertura
          : motivoReabertura as String?,
      assinaturaInvalidadaEm: assinaturaInvalidadaEm == _sentinel
          ? this.assinaturaInvalidadaEm
          : assinaturaInvalidadaEm as DateTime?,
      assinaturaInvalidadaPorUserId: assinaturaInvalidadaPorUserId == _sentinel
          ? this.assinaturaInvalidadaPorUserId
          : assinaturaInvalidadaPorUserId as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Rat &&
        other.id == id &&
        other.authorId == authorId &&
        other.empresaId == empresaId &&
        other.usuarioId == usuarioId &&
        other.tecnicoId == tecnicoId &&
        other.ownerType == ownerType &&
        other.numero == numero &&
        other.clienteNome == clienteNome &&
        other.responsavelRecebimento == responsavelRecebimento &&
        other.responsavelDocumento == responsavelDocumento &&
        other.dataVisita == dataVisita &&
        other.horarioInicioAtendimento == horarioInicioAtendimento &&
        other.horarioTerminoAtendimento == horarioTerminoAtendimento &&
        other.descricao == descricao &&
        other.equipamentoMovimentoTipo == equipamentoMovimentoTipo &&
        other.equipamentoDescricao == equipamentoDescricao &&
        other.equipamentoObservacao == equipamentoObservacao &&
        other.status == status &&
        other.syncStatus == syncStatus &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt &&
        other.ultimoAlteradorUserId == ultimoAlteradorUserId &&
        other.ultimaAlteracaoEm == ultimaAlteracaoEm &&
        other.reabertaParaCorrecaoEm == reabertaParaCorrecaoEm &&
        other.reabertaParaCorrecaoPorUserId == reabertaParaCorrecaoPorUserId &&
        other.motivoReabertura == motivoReabertura &&
        other.assinaturaInvalidadaEm == assinaturaInvalidadaEm &&
        other.assinaturaInvalidadaPorUserId == assinaturaInvalidadaPorUserId;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    authorId,
    empresaId,
    usuarioId,
    tecnicoId,
    ownerType,
    numero,
    clienteNome,
    responsavelRecebimento,
    responsavelDocumento,
    dataVisita,
    horarioInicioAtendimento,
    horarioTerminoAtendimento,
    descricao,
    equipamentoMovimentoTipo,
    equipamentoDescricao,
    equipamentoObservacao,
    status,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
    ultimoAlteradorUserId,
    ultimaAlteracaoEm,
    reabertaParaCorrecaoEm,
    reabertaParaCorrecaoPorUserId,
    motivoReabertura,
    assinaturaInvalidadaEm,
    assinaturaInvalidadaPorUserId,
  ]);
}

const Object _sentinel = Object();
