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

  bool get isDraft => status == RatStatus.draft;

  bool get isFinalizado => status == RatStatus.finalizado;

  bool get isArquivado => status == RatStatus.arquivado;

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
        other.deletedAt == deletedAt;
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
  ]);
}

const Object _sentinel = Object();
