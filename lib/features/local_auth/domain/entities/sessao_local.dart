enum SessaoModo {
  local,
}

enum SessaoLocalStatus {
  onboardingRequired,
  locked,
  unlocked,
}

class SessaoLocal {
  const SessaoLocal({
    required this.id,
    required this.tecnicoLocalId,
    required this.status,
    required this.pinConfigured,
    required this.biometriaDisponivel,
    required this.biometriaHabilitada,
    required this.onboardingConcluido,
    required this.createdAt,
    required this.updatedAt,
    this.lastUnlockedAt,
  }) : mode = SessaoModo.local;

  final String id;
  final SessaoModo mode;
  final String tecnicoLocalId;
  final SessaoLocalStatus status;
  final bool pinConfigured;
  final bool biometriaDisponivel;
  final bool biometriaHabilitada;
  final bool onboardingConcluido;
  final DateTime? lastUnlockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLocked => status == SessaoLocalStatus.locked;

  bool get isUnlocked => status == SessaoLocalStatus.unlocked;

  bool get requiresOnboarding =>
      status == SessaoLocalStatus.onboardingRequired;

  SessaoLocal copyWith({
    String? id,
    String? tecnicoLocalId,
    SessaoLocalStatus? status,
    bool? pinConfigured,
    bool? biometriaDisponivel,
    bool? biometriaHabilitada,
    bool? onboardingConcluido,
    Object? lastUnlockedAt = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessaoLocal(
      id: id ?? this.id,
      tecnicoLocalId: tecnicoLocalId ?? this.tecnicoLocalId,
      status: status ?? this.status,
      pinConfigured: pinConfigured ?? this.pinConfigured,
      biometriaDisponivel:
          biometriaDisponivel ?? this.biometriaDisponivel,
      biometriaHabilitada:
          biometriaHabilitada ?? this.biometriaHabilitada,
      onboardingConcluido:
          onboardingConcluido ?? this.onboardingConcluido,
      lastUnlockedAt: lastUnlockedAt == _sentinel
          ? this.lastUnlockedAt
          : lastUnlockedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SessaoLocal &&
        other.id == id &&
        other.mode == mode &&
        other.tecnicoLocalId == tecnicoLocalId &&
        other.status == status &&
        other.pinConfigured == pinConfigured &&
        other.biometriaDisponivel == biometriaDisponivel &&
        other.biometriaHabilitada == biometriaHabilitada &&
        other.onboardingConcluido == onboardingConcluido &&
        other.lastUnlockedAt == lastUnlockedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        mode,
        tecnicoLocalId,
        status,
        pinConfigured,
        biometriaDisponivel,
        biometriaHabilitada,
        onboardingConcluido,
        lastUnlockedAt,
        createdAt,
        updatedAt,
      );
}

const Object _sentinel = Object();
