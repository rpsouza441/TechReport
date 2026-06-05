import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:techreport/shared/infra/security/database_key_store.dart';
import 'package:techreport/shared/infra/database/tech_report_local_database.dart';
import 'package:techreport/shared/infra/debug/local_database_debug_log.dart';

/// Abre banco Drift com criptografia via SQLite3MultipleCiphers.
/// Aplica PRAGMA key, foreign_keys e valida cipher na conexao real.
QueryExecutor openEncryptedDatabase(String hexKey, {File? databaseFile}) {
  return LazyDatabase(() async {
    final file = databaseFile ?? await resolveLocalDatabaseFile();

    final escapedKey = hexKey.replaceAll("'", "''");
    final existsBeforeOpen = file.existsSync();

    LocalDatabaseDebugLog.info(
      'database.open.lazy.start',
      data: {
        'path': file.path,
        'existsBeforeOpen': existsBeforeOpen,
        'sizeBeforeOpenBytes': existsBeforeOpen ? file.lengthSync() : 0,
      },
    );

    _prepareDatabaseEncryptionIfNeeded(file, escapedKey);

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        LocalDatabaseDebugLog.info('database.native.setup.start');

        try {
          final cipher = rawDb.select('PRAGMA cipher;');
          LocalDatabaseDebugLog.info(
            'database.native.diagnostics.beforeKey',
            data: {'cipher': _rowsToLogData(cipher)},
          );

          _validateRawCipherRows(cipher);

          LocalDatabaseDebugLog.info(
            'database.native.key.apply.start',
            data: {'keyFormat': 'raw-hex', 'keyLength': hexKey.length},
          );

          rawDb.execute("PRAGMA key = 'raw:$escapedKey';");
          final sqliteMasterCount = rawDb.select(
            'SELECT count(*) AS count FROM sqlite_master;',
          );

          LocalDatabaseDebugLog.info(
            'database.native.key.apply.done',
            data: {'sqliteMasterCount': _rowsToLogData(sqliteMasterCount)},
          );

          LocalDatabaseDebugLog.info(
            'database.native.diagnostics.afterKey',
            data: _readRawDiagnostics(rawDb),
          );

          rawDb.execute('PRAGMA foreign_keys = ON;');
          final foreignKeys = rawDb.select('PRAGMA foreign_keys;');

          LocalDatabaseDebugLog.info(
            'database.native.setup.done',
            data: {'foreignKeys': _rowsToLogData(foreignKeys)},
          );
        } catch (error, stackTrace) {
          LocalDatabaseDebugLog.error(
            'database.native.setup.failed',
            error: error,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      },
    );
  });
}

Future<File> resolveLocalDatabaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, 'tech_report_local.db'));
}

void _prepareDatabaseEncryptionIfNeeded(File file, String escapedKey) {
  if (!file.existsSync() || file.lengthSync() == 0) {
    LocalDatabaseDebugLog.info('database.preEncryption.skip.emptyOrMissing');
    return;
  }

  final db = sqlite3.open(file.path);
  try {
    final sqliteMasterCount = db.select(
      'SELECT count(*) AS count FROM sqlite_master;',
    );

    LocalDatabaseDebugLog.info(
      'database.preEncryption.plaintext.detected',
      data: {
        'sqliteMasterCount': _rowsToLogData(sqliteMasterCount),
        'sizeBeforeRekeyBytes': file.lengthSync(),
      },
    );

    try {
      db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (error, stackTrace) {
      LocalDatabaseDebugLog.error(
        'database.preEncryption.walCheckpoint.failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    db.execute("PRAGMA rekey = 'raw:$escapedKey';");

    LocalDatabaseDebugLog.info(
      'database.preEncryption.rekey.done',
      data: {'keyFormat': 'raw-hex', 'sizeAfterRekeyBytes': file.lengthSync()},
    );
  } on SqliteException catch (error) {
    _rekeyLegacyPassphraseDatabaseIfNeeded(
      file,
      escapedKey,
      plaintextErrorMessage: error.message,
    );
  } finally {
    db.close();
  }
}

void _rekeyLegacyPassphraseDatabaseIfNeeded(
  File file,
  String escapedKey, {
  required String plaintextErrorMessage,
}) {
  final db = sqlite3.open(file.path);
  try {
    db.execute("PRAGMA key = '$escapedKey';");
    final sqliteMasterCount = db.select(
      'SELECT count(*) AS count FROM sqlite_master;',
    );

    LocalDatabaseDebugLog.info(
      'database.preEncryption.legacyPassphrase.detected',
      data: {
        'sqliteMasterCount': _rowsToLogData(sqliteMasterCount),
        'sizeBeforeRekeyBytes': file.lengthSync(),
      },
    );

    try {
      db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (error, stackTrace) {
      LocalDatabaseDebugLog.error(
        'database.preEncryption.legacyPassphrase.walCheckpoint.failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    db.execute("PRAGMA rekey = 'raw:$escapedKey';");

    LocalDatabaseDebugLog.info(
      'database.preEncryption.legacyPassphrase.rekey.done',
      data: {'keyFormat': 'raw-hex', 'sizeAfterRekeyBytes': file.lengthSync()},
    );
  } on SqliteException catch (error) {
    LocalDatabaseDebugLog.info(
      'database.preEncryption.skip.notPlaintext',
      data: {
        'plaintextMessage': plaintextErrorMessage,
        'legacyPassphraseMessage': error.message,
      },
    );
  } finally {
    db.close();
  }
}

/// Criacao do banco criptografado: carrega chave, abre executor e valida cipher.
/// Lanca [CipherValidationException] se sqlite3mc nao estiver ativo.
/// Teste de validacao: conferir `PRAGMA cipher;` em runtime/logs do app.
Future<TechReportLocalDatabase> buildEncryptedDatabase() async {
  LocalDatabaseDebugLog.info('database.build.start');
  final databaseFile = await resolveLocalDatabaseFile();
  final databaseExistsWithData =
      databaseFile.existsSync() && databaseFile.lengthSync() > 0;
  final keyStore = DatabaseKeyStore();
  final existingKey = await keyStore.readKey();

  if (existingKey == null && databaseExistsWithData) {
    throw MissingDatabaseKeyException(databaseFile.path);
  }

  final hexKey = existingKey ?? await keyStore.createKey();
  final db = TechReportLocalDatabase(
    openEncryptedDatabase(hexKey, databaseFile: databaseFile),
  );

  await logCipherState(db);

  LocalDatabaseDebugLog.info('database.build.done');
  return db;
}

void _validateRawCipherRows(List<Map<String, Object?>> rows) {
  final cipher = _readFirstPragmaValue(rows);
  if (cipher.isEmpty) {
    throw CipherValidationException(
      'PRAGMA cipher retornou vazio. '
      'SQLite3MultipleCiphers nao esta ativo ou a conexao nao esta usando '
      'a biblioteca esperada.',
    );
  }
}

/// Valida que o banco foi aberto com cipher ativo.
/// Lanca [CipherValidationException] se cipher nao responder.
class CipherValidationException implements Exception {
  final String message;
  CipherValidationException(this.message);
  @override
  String toString() => 'CipherValidationException: $message';
}

class MissingDatabaseKeyException implements Exception {
  MissingDatabaseKeyException(this.databasePath);

  final String databasePath;

  @override
  String toString() {
    return 'MissingDatabaseKeyException: banco local existe, mas a chave '
        'db_encryption_key nao foi encontrada. path=$databasePath';
  }
}

/// Loga cipher apos abertura do banco. A validacao obrigatoria fica no setup.
Future<void> logCipherState(TechReportLocalDatabase db) async {
  final result = await db.customSelect('PRAGMA cipher;').get();
  final cipher = result.isEmpty
      ? ''
      : result.first.data.values.map((value) => '$value').join().trim();
  if (cipher.isEmpty) {
    LocalDatabaseDebugLog.error(
      'database.validateCipher.emptyAfterSetup',
      data: {
        'message':
            'PRAGMA cipher retornou vazio apos setup ja validado. '
            'Investigar runtime sqlite3mc.',
      },
    );
    return;
  }

  LocalDatabaseDebugLog.info(
    'database.validateCipher.done',
    data: {'cipher': result.map((row) => row.data).toList()},
  );
}

String _readFirstPragmaValue(List<Map<String, Object?>> rows) {
  if (rows.isEmpty) return '';
  return rows.first.values.map((value) => '$value').join().trim();
}

Map<String, Object?> _readRawDiagnostics(dynamic rawDb) {
  final sqliteVersion = rawDb.select(
    'SELECT sqlite_version() AS sqlite_version;',
  );
  final sqliteSourceId = rawDb.select(
    'SELECT sqlite_source_id() AS sqlite_source_id;',
  );
  final cipher = rawDb.select('PRAGMA cipher;');
  final compileOptions = rawDb.select('PRAGMA compile_options;');

  return {
    'sqliteVersion': _rowsToLogData(sqliteVersion),
    'sqliteSourceId': _rowsToLogData(sqliteSourceId),
    'cipher': _rowsToLogData(cipher),
    'compileOptionsCount': compileOptions.length,
  };
}

List<Object?> _rowsToLogData(dynamic rows) {
  return (rows as Iterable).map((row) => _rowToLogData(row)).toList();
}

Object? _rowToLogData(dynamic row) {
  if (row is Map) return Map<String, Object?>.from(row);
  return '$row';
}
