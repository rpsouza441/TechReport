import 'package:techreport/features/rat/domain/entities/rat_remote_snapshot.dart';

abstract class RemoteRatRepository {
  Future<void> upsertFromPayload(String payload);

  Future<void> softDeleteFromPayload(String payload);

  Future<List<RatRemoteSnapshot>> fetchUpdatedSince({
    required String empresaId,
    required DateTime? since,
  });
}
