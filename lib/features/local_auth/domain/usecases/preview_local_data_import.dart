import 'package:techreport/features/local_auth/domain/entities/local_import_preview.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';

class PreviewLocalDataImport {
  PreviewLocalDataImport({required RatRepository ratRepository})
    : _ratRepository = ratRepository;

  final RatRepository _ratRepository;

  Future<LocalImportPreview> call(Map<String, dynamic> payload) async {
    final rats = payload['rats'] as List;
    final assinaturas = payload['assinaturas'] as List;
    final exportedAtRaw = payload['exportedAt'] as String?;

    var newRats = 0;
    var duplicateRats = 0;
    var conflictingRats = 0;
    var invalidItems = 0;

    for (final item in rats) {
      if (item is! Map<String, dynamic>) {
        invalidItems++;
        continue;
      }

      final id = item['id'];
      final updatedAt = DateTime.tryParse(item['updatedAt'] as String? ?? '');
      if (id is! String || id.isEmpty || updatedAt == null) {
        invalidItems++;
        continue;
      }

      final existing = await _ratRepository.getById(id);
      if (existing == null) {
        newRats++;
      } else if (existing.deletedAt != null) {
        newRats++;
      } else if (existing.updatedAt.isAtSameMomentAs(updatedAt)) {
        duplicateRats++;
      } else {
        conflictingRats++;
      }
    }

    return LocalImportPreview(
      schema: payload['schema'] as String? ?? '',
      exportedAt: exportedAtRaw == null
          ? null
          : DateTime.tryParse(exportedAtRaw),
      totalRats: rats.length,
      totalAssinaturas: assinaturas.length,
      newRats: newRats,
      duplicateRats: duplicateRats,
      conflictingRats: conflictingRats,
      invalidItems: invalidItems,
    );
  }
}
