import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:techreport/shared/infra/debug/local_database_debug_log.dart';

/// Armazena chave de criptografia do banco local em secure storage.
/// A chave e gerada uma vez e persistida ate que reset local explicito a delete.
class DatabaseKeyStore {
  DatabaseKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyName = 'db_encryption_key';

  final FlutterSecureStorage _storage;

  /// Retorna chave existente sem criar uma nova.
  Future<String?> readKey() async {
    LocalDatabaseDebugLog.info('databaseKeyStore.read.start');

    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      LocalDatabaseDebugLog.info(
        'databaseKeyStore.read.existing',
        data: {
          'keyName': _keyName,
          'fingerprint': _fingerprint(existing),
          'length': existing.length,
        },
      );
      return existing;
    }

    LocalDatabaseDebugLog.info('databaseKeyStore.read.missing');
    return null;
  }

  /// Retorna chave existente ou gera nova chave de 32 bytes em hex.
  Future<String> getOrCreateKey() async {
    final existing = await readKey();
    if (existing != null) return existing;
    return createKey();
  }

  /// Cria e persiste uma nova chave. Usar apenas quando nao ha banco existente.
  Future<String> createKey() async {
    final key = _generateKey();
    await _storage.write(key: _keyName, value: key);
    LocalDatabaseDebugLog.info(
      'databaseKeyStore.write.created',
      data: {
        'keyName': _keyName,
        'fingerprint': _fingerprint(key),
        'length': key.length,
      },
    );
    return key;
  }

  /// Apaga chave. Usado apenas em acao explicita de reset local.
  Future<void> deleteKey() async {
    LocalDatabaseDebugLog.info('databaseKeyStore.delete');
    await _storage.delete(key: _keyName);
  }

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _fingerprint(String value) {
    final digest = sha256.convert(utf8.encode(value)).toString();
    return digest.substring(0, 12);
  }
}
