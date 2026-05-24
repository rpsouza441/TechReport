import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:techreport/features/sync/domain/repositories/sync_checkpoint_repository.dart';

class LocalSyncCheckpointRepository implements SyncCheckpointRepository {
  LocalSyncCheckpointRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  // Formato: sync.rats.last_download_at.<empresaId>.<usuarioId>.<papel>
  // Inclui papel para evitar que técnico e gerente compartilhem checkpoint
  // no mesmo aparelho, o que causaria downloads incrementais incompletos.
  static const _ratDownloadPrefix = 'sync.rats.last_download_at';

  final FlutterSecureStorage _storage;

  @override
  Future<DateTime?> getLastRatDownloadAt({
    required String empresaId,
    required String usuarioId,
    required String papel,
  }) async {
    final rawValue = await _storage.read(key: _key(empresaId, usuarioId, papel));
    if (rawValue == null) return null;
    return DateTime.tryParse(rawValue);
  }

  @override
  Future<void> saveLastRatDownloadAt({
    required String empresaId,
    required String usuarioId,
    required String papel,
    required DateTime value,
  }) async {
    await _storage.write(
      key: _key(empresaId, usuarioId, papel),
      value: value.toIso8601String(),
    );
  }

  String _key(String empresaId, String usuarioId, String papel) {
    return '$_ratDownloadPrefix.$empresaId.$usuarioId.$papel';
  }
}
