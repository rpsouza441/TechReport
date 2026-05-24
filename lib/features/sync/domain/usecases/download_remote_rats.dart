import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/repositories/remote_rat_repository.dart';
import 'package:techreport/features/sync/domain/repositories/sync_checkpoint_repository.dart';

class DownloadRemoteRats {
  const DownloadRemoteRats({
    required RemoteRatRepository remoteRatRepository,
    required RatRepository ratRepository,
    required SyncCheckpointRepository checkpointRepository,
  }) : _remoteRatRepository = remoteRatRepository,
       _ratRepository = ratRepository,
       _checkpointRepository = checkpointRepository;

  final RemoteRatRepository _remoteRatRepository;
  final RatRepository _ratRepository;
  final SyncCheckpointRepository _checkpointRepository;

  Future<void> call({
    required String empresaId,
    required String usuarioId,
    required String papel,
  }) async {
    final since = await _checkpointRepository.getLastRatDownloadAt(
      empresaId: empresaId,
      usuarioId: usuarioId,
      papel: papel,
    );

    final snapshots = await _remoteRatRepository.fetchUpdatedSince(
      empresaId: empresaId,
      since: since,
    );

    DateTime? newestServerUpdate;

    for (final snapshot in snapshots) {
      await _ratRepository.save(snapshot.rat);

      final serverUpdatedAt = snapshot.serverUpdatedAt;
      if (newestServerUpdate == null ||
          serverUpdatedAt.isAfter(newestServerUpdate)) {
        newestServerUpdate = serverUpdatedAt;
      }
    }

    if (newestServerUpdate != null) {
      await _checkpointRepository.saveLastRatDownloadAt(
        empresaId: empresaId,
        usuarioId: usuarioId,
        papel: papel,
        value: newestServerUpdate,
      );
    }
  }
}
