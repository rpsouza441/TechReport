enum SessaoRemotaPapelGlobal { appAdmin }

enum SessaoRemotaPapelEmpresa { adminEmpresa, gerente, tecnico }

enum SessaoRemotaStatus { valid, expired, offlineAllowed, invalid }

const _sentinel = Object();

class SessaoRemota {
  const SessaoRemota({
    required this.id,
    required this.empresaId,
    required this.usuarioId,
    required this.tecnicoId,
    required this.papelGlobal,
    required this.papelEmpresa,
    required this.accessTokenRef,
    required this.refreshTokenRef,
    required this.endpointRef,
    required this.expiresAt,
    required this.lastValidatedAt,
    required this.offlineAccessUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? empresaId;
  final String usuarioId;
  final String? tecnicoId;
  final SessaoRemotaPapelGlobal? papelGlobal;
  final SessaoRemotaPapelEmpresa? papelEmpresa;
  final String accessTokenRef;
  final String refreshTokenRef;
  final String endpointRef;
  final DateTime expiresAt;
  final DateTime lastValidatedAt;
  final DateTime offlineAccessUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get canUseOffline => DateTime.now().isBefore(offlineAccessUntil);

  bool get isAppAdmin => papelGlobal == SessaoRemotaPapelGlobal.appAdmin;

  bool get isAdminEmpresa =>
      papelEmpresa == SessaoRemotaPapelEmpresa.adminEmpresa;

  bool get isGerente => papelEmpresa == SessaoRemotaPapelEmpresa.gerente;

  bool get isTecnico => papelEmpresa == SessaoRemotaPapelEmpresa.tecnico;

  bool get hasCompanyContext => empresaId != null && tecnicoId != null;

  SessaoRemotaStatus get status {
    if (!isExpired) {
      return SessaoRemotaStatus.valid;
    }

    if (canUseOffline) {
      return SessaoRemotaStatus.offlineAllowed;
    }

    return SessaoRemotaStatus.expired;
  }

  SessaoRemota copyWith({
    String? id,
    Object? empresaId = _sentinel,
    String? usuarioId,
    Object? tecnicoId = _sentinel,
    Object? papelGlobal = _sentinel,
    Object? papelEmpresa = _sentinel,
    String? accessTokenRef,
    String? refreshTokenRef,
    String? endpointRef,
    DateTime? expiresAt,
    DateTime? lastValidatedAt,
    DateTime? offlineAccessUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessaoRemota(
      id: id ?? this.id,
      empresaId: empresaId == _sentinel ? this.empresaId : empresaId as String?,
      usuarioId: usuarioId ?? this.usuarioId,
      tecnicoId: tecnicoId == _sentinel ? this.tecnicoId : tecnicoId as String?,
      papelGlobal: papelGlobal == _sentinel
          ? this.papelGlobal
          : papelGlobal as SessaoRemotaPapelGlobal?,
      papelEmpresa: papelEmpresa == _sentinel
          ? this.papelEmpresa
          : papelEmpresa as SessaoRemotaPapelEmpresa?,
      accessTokenRef: accessTokenRef ?? this.accessTokenRef,
      refreshTokenRef: refreshTokenRef ?? this.refreshTokenRef,
      endpointRef: endpointRef ?? this.endpointRef,
      expiresAt: expiresAt ?? this.expiresAt,
      lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
      offlineAccessUntil: offlineAccessUntil ?? this.offlineAccessUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SessaoRemota &&
        other.id == id &&
        other.empresaId == empresaId &&
        other.usuarioId == usuarioId &&
        other.tecnicoId == tecnicoId &&
        other.papelGlobal == papelGlobal &&
        other.papelEmpresa == papelEmpresa &&
        other.accessTokenRef == accessTokenRef &&
        other.refreshTokenRef == refreshTokenRef &&
        other.endpointRef == endpointRef &&
        other.expiresAt == expiresAt &&
        other.lastValidatedAt == lastValidatedAt &&
        other.offlineAccessUntil == offlineAccessUntil &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    empresaId,
    usuarioId,
    tecnicoId,
    papelGlobal,
    papelEmpresa,
    accessTokenRef,
    refreshTokenRef,
    endpointRef,
    expiresAt,
    lastValidatedAt,
    offlineAccessUntil,
    createdAt,
    updatedAt,
  );
}
