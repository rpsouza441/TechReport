import 'package:flutter/foundation.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/domain/entities/local_import_preview.dart';
import 'package:techreport/features/local_auth/domain/entities/local_import_result.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_backup.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_backup.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_data_import.dart';

class LocalDataImportViewModel extends ChangeNotifier {
  LocalDataImportViewModel({
    required PreviewLocalBackup previewLocalBackup,
    required ApplyLocalBackup applyLocalBackup,
    required LocalDataImportParser localDataImportParser,
    required PreviewLocalDataImport previewLocalDataImport,
    required ApplyLocalDataImport applyLocalDataImport,
  }) : _previewLocalBackup = previewLocalBackup,
       _applyLocalBackup = applyLocalBackup,
       _localDataImportParser = localDataImportParser,
       _previewLocalDataImport = previewLocalDataImport,
       _applyLocalDataImport = applyLocalDataImport;

  final PreviewLocalBackup _previewLocalBackup;
  final ApplyLocalBackup _applyLocalBackup;
  final LocalDataImportParser _localDataImportParser;
  final PreviewLocalDataImport _previewLocalDataImport;
  final ApplyLocalDataImport _applyLocalDataImport;

  bool isLoading = false;
  String? errorMessage;
  LocalImportPreview? preview;
  LocalImportResult? result;
  List<int>? _backupBytes;
  Map<String, dynamic>? _legacyPayload;
  bool _isLegacy = false;

  bool get isLegacy => _isLegacy;
  bool get hasSelection => _backupBytes != null || _legacyPayload != null;

  Future<void> loadBackup(List<int> bytes) async {
    isLoading = true;
    errorMessage = null;
    preview = null;
    result = null;
    _backupBytes = null;
    _legacyPayload = null;
    _isLegacy = false;
    notifyListeners();

    try {
      preview = await _previewLocalBackup(bytes);
      _backupBytes = bytes;
    } on FormatException {
      // Não é ZIP — tenta legado
      try {
        _legacyPayload = _localDataImportParser.parse(
          String.fromCharCodes(bytes),
        );
        preview = await _previewLocalDataImport(_legacyPayload!);
        _isLegacy = true;
      } on FormatException catch (e) {
        errorMessage = _cleanError(e);
      }
    } catch (e) {
      errorMessage = _cleanError(e);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> apply({
    required LocalImportConflictPolicy conflictPolicy,
  }) async {
    isLoading = true;
    errorMessage = null;
    result = null;
    notifyListeners();

    try {
      if (_isLegacy) {
        final payload = _legacyPayload;
        if (payload == null) {
          errorMessage = 'Selecione um backup antes de importar.';
          isLoading = false;
          notifyListeners();
          return;
        }
        result = await _applyLocalDataImport(
          payload: payload,
          conflictPolicy: conflictPolicy,
        );
      } else {
        final bytes = _backupBytes;
        if (bytes == null) {
          errorMessage = 'Selecione um backup antes de importar.';
          isLoading = false;
          notifyListeners();
          return;
        }
        result = await _applyLocalBackup(
          bytes: bytes,
          conflictPolicy: conflictPolicy,
        );
      }
    } catch (e) {
      errorMessage = _cleanError(e);
    }

    isLoading = false;
    notifyListeners();
  }

  void reset() {
    isLoading = false;
    errorMessage = null;
    preview = null;
    result = null;
    _backupBytes = null;
    _legacyPayload = null;
    _isLegacy = false;
    notifyListeners();
  }

  String _cleanError(Object error) {
    final message = error.toString();
    return message.replaceFirst('FormatException: ', '');
  }
} // end of LocalDataImportViewModel
