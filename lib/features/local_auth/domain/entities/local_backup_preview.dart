import 'package:techreport/features/local_auth/domain/entities/local_import_preview.dart';

class LocalBackupPreview extends LocalImportPreview {
  const LocalBackupPreview({
    required super.schema,
    required super.exportedAt,
    required super.totalRats,
    required super.totalAssinaturas,
    required super.newRats,
    required super.duplicateRats,
    required super.conflictingRats,
    required super.invalidItems,
    required this.appVersion,
    required this.databaseSchemaVersion,
    required this.checksumsValid,
  });

  final String appVersion;
  final int databaseSchemaVersion;
  final bool checksumsValid;

  @override
  bool get canApply => checksumsValid && super.canApply;
}
