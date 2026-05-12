import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:techreport/features/sync/domain/repositories/sync_checkpoint_repository.dart';

class LocalSyncCheckpointRepository implements SyncCheckpointRepository {
  LocalSyncCheckpointRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _ratDownloadPrefix = 'sync.rats.last_download_at';

  final FlutterSecureStorage _storage;

  @override
  Future<DateTime?> getLastRatDownloadAt(String empresaId) async {
    final rawValue = await _storage.read(key: _key(empresaId));
    if (rawValue == null) {
      return null;
    }

    return DateTime.parse(rawValue);
  }

  @override
  Future<void> saveLastRatDownloadAt({
    required String empresaId,
    required DateTime value,
  }) async {
    await _storage.write(key: _key(empresaId), value: value.toIso8601String());
  }

  String _key(String empresaId) {
    return '$_ratDownloadPrefix.$empresaId';
  }
}
