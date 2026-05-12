abstract class SyncCheckpointRepository {
  Future<DateTime?> getLastRatDownloadAt(String empresaId);

  Future<void> saveLastRatDownloadAt({
    required String empresaId,
    required DateTime value,
  });
}
