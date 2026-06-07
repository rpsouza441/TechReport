abstract class RemoteAssinaturaRepository {
  Future<String> uploadSignature({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
    required int version,
    required List<int> bytes,
    required String mimeType,
  });

  Future<void> upsertMetadata({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
    required String storagePath,
    required String sha256,
    required int sizeBytes,
    required String mimeType,
    required int version,
    required DateTime? deletedAt,
  });

  Future<String> createSignedUrl({
    required String storagePath,
    int expiresInSeconds = 300,
  });

  Future<bool> objectExists(String storagePath);

  Future<void> deleteStorageObject(String storagePath);

  Future<void> markDeleted({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
  });
}