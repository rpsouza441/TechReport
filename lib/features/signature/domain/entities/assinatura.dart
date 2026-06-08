import 'dart:typed_data';

enum StorageMode { localFile, inlineBinary, remoteAsset }

class Assinatura {
  const Assinatura({
    required this.id,
    required this.ratId,
    required this.storageMode,
    required this.assetRef,
    this.data,
    this.sizeBytes,
    this.sha256,
    this.mimeType,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String ratId;
  final StorageMode storageMode;
  final String assetRef;
  final Uint8List? data;
  final int? sizeBytes;
  final String? sha256;
  final String? mimeType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Assinatura copyWith({
    String? id,
    String? ratId,
    StorageMode? storageMode,
    String? assetRef,
    Uint8List? data,
    Object? dataSet = _sentinel,
    int? sizeBytes,
    Object? sizeBytesSet = _sentinel,
    String? sha256,
    Object? sha256Set = _sentinel,
    String? mimeType,
    Object? mimeTypeSet = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _sentinel,
  }) {
    return Assinatura(
      id: id ?? this.id,
      ratId: ratId ?? this.ratId,
      storageMode: storageMode ?? this.storageMode,
      assetRef: assetRef ?? this.assetRef,
      data: dataSet == _sentinel
          ? data
          : dataSet == _nullMark
          ? null
          : dataSet as Uint8List?,
      sizeBytes: sizeBytesSet == _sentinel
          ? sizeBytes
          : sizeBytesSet == _nullMark
          ? null
          : sizeBytesSet as int?,
      sha256: sha256Set == _sentinel
          ? sha256
          : sha256Set == _nullMark
          ? null
          : sha256Set as String?,
      mimeType: mimeTypeSet == _sentinel
          ? mimeType
          : mimeTypeSet == _nullMark
          ? null
          : mimeTypeSet as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt == _sentinel
          ? this.deletedAt
          : deletedAt == _nullMark
          ? null
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
        other.data == data &&
        other.sizeBytes == sizeBytes &&
        other.sha256 == sha256 &&
        other.mimeType == mimeType &&
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
    data,
    sizeBytes,
    sha256,
    mimeType,
    createdAt,
    updatedAt,
    deletedAt,
  );
}

const Object _sentinel = Object();
const Object _nullMark = Object();
