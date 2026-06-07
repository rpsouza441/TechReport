import 'package:techreport/features/local_auth/data/services/local_backup_parser.dart';
import 'package:techreport/features/local_auth/domain/entities/local_import_result.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';

class ApplyLocalBackup {
  ApplyLocalBackup({
    required LocalBackupParser parser,
    required ApplyLocalDataImport applyLocalDataImport,
  }) : _parser = parser,
       _applyLocalDataImport = applyLocalDataImport;

  final LocalBackupParser _parser;
  final ApplyLocalDataImport _applyLocalDataImport;

  Future<LocalImportResult> call({
    required List<int> bytes,
    required LocalImportConflictPolicy conflictPolicy,
  }) async {
    if (!_parser.validateIntegrity(bytes)) {
      throw const FormatException(
        'Backup corrompido:checksum divergente.',
      );
    }

    final rats = _parser.parseRats(bytes);
    final assinaturas = _parser.parseAssinaturas(bytes);

    final payload = <String, dynamic>{
      'rats': rats,
      'assinaturas': assinaturas,
    };

    return _applyLocalDataImport.call(
      payload: payload,
      conflictPolicy: conflictPolicy,
    );
  }
}