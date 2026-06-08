import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/domain/entities/local_backup_preview.dart';

class PreviewLocalBackup {
  PreviewLocalBackup({required LocalBackupParser parser}) : _parser = parser;

  final LocalBackupParser _parser;

  Future<LocalBackupPreview> call(List<int> bytes) async {
    final manifest = _parser.parseManifest(bytes);
    final rats = _parser.parseRats(bytes);
    final assinaturas = _parser.parseAssinaturas(bytes);
    final checksumsValid = _parser.validateIntegrity(bytes);

    var newRats = 0;
    const duplicateRats = 0;
    const conflictingRats = 0;
    var invalidItems = 0;

    if (rats.isEmpty && assinaturas.isEmpty) {
      invalidItems = 1;
    }

    for (final item in rats) {
      final id = item['id'];
      final updatedAt = DateTime.tryParse(item['updatedAt'] as String? ?? '');
      if (id is! String || id.isEmpty || updatedAt == null) {
        invalidItems++;
        continue;
      }
      newRats++;
    }

    return LocalBackupPreview(
      schema: manifest.schema,
      exportedAt: manifest.createdAt,
      totalRats: rats.length,
      totalAssinaturas: assinaturas.length,
      newRats: newRats,
      duplicateRats: duplicateRats,
      conflictingRats: conflictingRats,
      invalidItems: invalidItems,
      appVersion: manifest.appVersion,
      databaseSchemaVersion: manifest.databaseSchemaVersion,
      checksumsValid: checksumsValid,
    );
  }
}
