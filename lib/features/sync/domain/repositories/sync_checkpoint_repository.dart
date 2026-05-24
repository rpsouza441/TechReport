abstract class SyncCheckpointRepository {
  Future<DateTime?> getLastRatDownloadAt({
    required String empresaId,
    required String usuarioId,
    required String papel,
  });

  Future<void> saveLastRatDownloadAt({
    required String empresaId,
    required String usuarioId,
    required String papel,
    required DateTime value,
  });
}
