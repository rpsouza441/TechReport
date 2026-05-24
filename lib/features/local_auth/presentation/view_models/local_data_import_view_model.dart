import 'package:flutter/foundation.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/domain/entities/local_import_preview.dart';
import 'package:techreport/features/local_auth/domain/entities/local_import_result.dart';
import 'package:techreport/features/local_auth/domain/usecases/apply_local_data_import.dart';
import 'package:techreport/features/local_auth/domain/usecases/preview_local_data_import.dart';

class LocalDataImportViewModel extends ChangeNotifier {
  LocalDataImportViewModel({
    required LocalDataImportParser parser,
    required PreviewLocalDataImport previewImport,
    required ApplyLocalDataImport applyImport,
  }) : _parser = parser,
       _previewImport = previewImport,
       _applyImport = applyImport;

  final LocalDataImportParser _parser;
  final PreviewLocalDataImport _previewImport;
  final ApplyLocalDataImport _applyImport;

  bool isLoading = false;
  String? errorMessage;
  LocalImportPreview? preview;
  LocalImportResult? result;
  Map<String, dynamic>? _payload;

  Future<void> previewRawJson(String rawJson) async {
    isLoading = true;
    errorMessage = null;
    preview = null;
    result = null;
    _payload = null;
    notifyListeners();

    try {
      final parsed = _parser.parse(rawJson);
      _payload = parsed;
      preview = await _previewImport(parsed);
    } catch (e) {
      errorMessage = _cleanError(e);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> apply({
    required LocalImportConflictPolicy conflictPolicy,
  }) async {
    final payload = _payload;
    if (payload == null) {
      errorMessage = 'Selecione um backup antes de importar.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    result = null;
    notifyListeners();

    try {
      result = await _applyImport(
        payload: payload,
        conflictPolicy: conflictPolicy,
      );
    } catch (e) {
      errorMessage = _cleanError(e);
    }

    isLoading = false;
    notifyListeners();
  }

  String _cleanError(Object error) {
    final message = error.toString();
    return message.replaceFirst('FormatException: ', '');
  }
}
