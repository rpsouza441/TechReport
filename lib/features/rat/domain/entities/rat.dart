enum RatStatus { draft, finalizado, enviado, arquivado }

enum RatSyncStatus { localOnly, pendingSync, synced, syncError }

enum RatOwnerType { localTecnico, companyTecnico }

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
    required this.descricao,
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
  final String descricao;
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
    String? descricao,
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
      descricao: descricao ?? this.descricao,
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
        other.descricao == descricao &&
        other.status == status &&
        other.syncStatus == syncStatus &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    authorId,
    empresaId,
    usuarioId,
    tecnicoId,
    ownerType,
    numero,
    clienteNome,
    descricao,
    status,
    syncStatus,
    createdAt,
    updatedAt,
    deletedAt,
  );
}

const Object _sentinel = Object();
