import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class LocalSignatureAssetStore {
  static const _signatureDirectoryName = 'signatures';

  Future<String> savePng({
    required String assinaturaId,
    required Uint8List bytes,
  }) async {
    final directory = await _signatureDirectory();
    final fileName = '$assinaturaId.png';
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');

    await file.writeAsBytes(bytes, flush: true);
    return '$_signatureDirectoryName/$fileName';
  }

  Future<Uint8List?> read(String assetRef) async {
    final file = await _fileFromAssetRef(assetRef);
    if (!await file.exists()) {
      return null;
    }

    return file.readAsBytes();
  }

  Future<void> delete(String assetRef) async {
    final file = await _fileFromAssetRef(assetRef);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _signatureDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${appDirectory.path}${Platform.pathSeparator}$_signatureDirectoryName',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<File> _fileFromAssetRef(String assetRef) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final normalizedRef = assetRef.replaceAll('/', Platform.pathSeparator);
    return File('${appDirectory.path}${Platform.pathSeparator}$normalizedRef');
  }
}
