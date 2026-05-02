enum SessaoRemotaStatus { valid, expired, offlineAllowed, invalid }

class SessaoRemota {
  const SessaoRemota({
    required this.id,
    required this.empresaId,
    required this.usuarioId,
    required this.tecnicoId,
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
  final String empresaId;
  final String usuarioId;
  final String tecnicoId;
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
    String? empresaId,
    String? usuarioId,
    String? tecnicoId,
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
      empresaId: empresaId ?? this.empresaId,
      usuarioId: usuarioId ?? this.usuarioId,
      tecnicoId: tecnicoId ?? this.tecnicoId,
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
