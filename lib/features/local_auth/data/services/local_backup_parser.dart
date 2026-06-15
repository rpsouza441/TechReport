import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:techreport/features/local_auth/data/services/local_data_import_parser.dart';
import 'package:techreport/features/local_auth/domain/entities/local_backup_manifest.dart';

class LocalBackupParser {
  LocalBackupParser({LocalDataImportParser? legacyParser})
    : _legacyParser = legacyParser ?? LocalDataImportParser();

  final LocalDataImportParser _legacyParser;

  LocalBackupManifest parseManifest(List<int> bytes) {
    final archive = _tryDecodeZip(bytes);
    if (archive == null) {
      throw const FormatException('Arquivo de backup inválido.');
    }

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('Backup corrompido: manifest.json ausente.');
    }

    Map<String, dynamic> manifestJson;
    try {
      manifestJson =
          jsonDecode(utf8.decode(manifestFile.content as List<int>))
              as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Backup corrompido: manifest.json ilegível.');
    }

    final schema = manifestJson['schema'] as String?;
    if (schema != 'techreport.backup.v1') {
      throw const FormatException('Versão de backup não suportada.');
    }

    try {
      return LocalBackupManifest.fromJson(manifestJson);
    } catch (_) {
      throw const FormatException(
        'Backup corrompido: manifest com estrutura inválida.',
      );
    }
  }

  bool validateIntegrity(List<int> bytes) {
    Archive? archive = _tryDecodeZip(bytes);

    if (archive != null) {
      return _validateZipIntegrity(archive);
    }

    // Legacy JSON — validação limitada, apenas verifica que o JSON é parseável
    // e calcula hash do conteúdo para registro/debug.
    // NOTE: Sem checksum externo, não detecta tampering.
    try {
      final content = utf8.decode(bytes as Uint8List);
      _legacyParser.parse(content);
      final hash = sha256.convert(bytes).toString();
      debugPrint('Legacy backup integrity: parsed OK, SHA-256=$hash');
      return true;
    } catch (e, st) {
      debugPrint('Legacy backup parse error: $e\n$st');
      return false;
    }
  }

  List<Map<String, dynamic>> parseRats(List<int> bytes) {
    final archive = _tryDecodeZip(bytes);
    if (archive != null) {
      final ratsFile = archive.findFile('data/rats.json');
      if (ratsFile == null) {
        throw const FormatException(
          'Backup corrompido: data/rats.json ausente.',
        );
      }
      final decoded =
          jsonDecode(utf8.decode(ratsFile.content as List<int>)) as List;
      return decoded.cast<Map<String, dynamic>>();
    }

    // Legacy
    final payload = _legacyParser.parse(utf8.decode(bytes as Uint8List));
    return (payload['rats'] as List).cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> parseAssinaturas(List<int> bytes) {
    final archive = _tryDecodeZip(bytes);
    if (archive != null) {
      final assinaturasFile = archive.findFile('data/assinaturas.json');
      if (assinaturasFile == null) {
        throw const FormatException(
          'Backup corrompido: data/assinaturas.json ausente.',
        );
      }
      final decoded =
          jsonDecode(utf8.decode(assinaturasFile.content as List<int>)) as List;
      return decoded.cast<Map<String, dynamic>>();
    }

    // Legacy
    final payload = _legacyParser.parse(utf8.decode(bytes as Uint8List));
    return (payload['assinaturas'] as List).cast<Map<String, dynamic>>();
  }

  Archive? _tryDecodeZip(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes as Uint8List);
      return archive;
    } catch (_) {
      return null;
    }
  }

  bool _validateZipIntegrity(Archive archive) {
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) return false;

    Map<String, dynamic> manifestJson;
    try {
      manifestJson =
          jsonDecode(utf8.decode(manifestFile.content as List<int>))
              as Map<String, dynamic>;
    } catch (_) {
      return false;
    }

    final checksumsJson = manifestJson['checksums'] as Map<String, dynamic>?;
    if (checksumsJson == null) return false;

    for (final entry in checksumsJson.entries) {
      final path = entry.key;
      final expectedChecksum = entry.value as String;
      final file = archive.findFile(path);
      if (file == null) return false;

      final actualChecksum = sha256
          .convert(file.content as List<int>)
          .toString();
      if (actualChecksum != expectedChecksum) return false;
    }

    return true;
  }
}
