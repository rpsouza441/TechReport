enum StorageMode { localFile, inlineBinary, remoteAsset }

class Assinatura {
  const Assinatura({
    required this.id,
    required this.ratId,
    required this.storageMode,
    required this.assetRef,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String ratId;
  final StorageMode storageMode;
  final String assetRef;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Assinatura copyWith({
    String? id,
    String? ratId,
    StorageMode? storageMode,
    String? assetRef,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _sentinel,
  }) {
    return Assinatura(
      id: id ?? this.id,
      ratId: ratId ?? this.ratId,
      storageMode: storageMode ?? this.storageMode,
      assetRef: assetRef ?? this.assetRef,
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
    return other is Assinatura &&
        other.id == id &&
        other.ratId == ratId &&
        other.storageMode == storageMode &&
        other.assetRef == assetRef &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    ratId,
    storageMode,
    assetRef,
    createdAt,
    updatedAt,
    deletedAt,
  );
}

const Object _sentinel = Object();
