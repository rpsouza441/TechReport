import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/shared/infra/database/open_encrypted_database.dart';
import 'package:techreport/shared/infra/database/tech_report_local_database.dart';

const _validKey =
    '000102030405060708090a0b0c0d0e0f'
    '101112131415161718191a1b1c1d1e1f';
const _wrongKey =
    'f0e0d0c0b0a090807060504030201000'
    '0f1e2d3c4b5a69788796a5b4c3d2e1f0';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDirectory;
  late File databaseFile;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'techreport-key-safety-',
    );
    databaseFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}'
      'tech_report_local.db',
    );
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDirectory.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('abertura fail-safe do banco criptografado', () {
    test(
      'banco existente sem chave falha sem recriar arquivo ou chave',
      () async {
        final originalBytes = List<int>.generate(128, (index) => index);
        await databaseFile.writeAsBytes(originalBytes, flush: true);

        await expectLater(
          buildEncryptedDatabase(),
          throwsA(
            isA<MissingDatabaseKeyException>().having(
              (error) => error.databasePath,
              'databasePath',
              databaseFile.path,
            ),
          ),
        );

        expect(databaseFile.existsSync(), isTrue);
        expect(await databaseFile.readAsBytes(), originalBytes);
        expect(
          await const FlutterSecureStorage().read(key: 'db_encryption_key'),
          isNull,
          reason: 'banco existente nunca pode acionar criacao de chave',
        );
      },
    );

    test('chave armazenada valida preserva registros existentes', () async {
      await _createEncryptedSentinel(databaseFile, _validKey);
      final beforeOpen = await databaseFile.readAsBytes();
      FlutterSecureStorage.setMockInitialValues({
        'db_encryption_key': _validKey,
      });

      final database = await buildEncryptedDatabase();
      final rows = await database
          .customSelect('SELECT value FROM phase_20_2_key_safety')
          .get();

      expect(rows.single.read<String>('value'), 'registro-preservado');
      await database.close();
      expect(databaseFile.existsSync(), isTrue);
      expect(databaseFile.lengthSync(), beforeOpen.length);
    });

    test(
      'chave errada falha sem resetar dados nem vazar material da chave',
      () async {
        await _createEncryptedSentinel(databaseFile, _validKey);
        final beforeOpen = await databaseFile.readAsBytes();
        FlutterSecureStorage.setMockInitialValues({
          'db_encryption_key': _wrongKey,
        });
        final logs = <String>[];
        final previousDebugPrint = debugPrint;
        Object? openingError;

        debugPrint = (message, {wrapWidth}) {
          if (message != null) logs.add(message);
        };
        try {
          await buildEncryptedDatabase();
        } catch (error) {
          openingError = error;
        } finally {
          debugPrint = previousDebugPrint;
        }

        expect(openingError, isNotNull);
        expect(databaseFile.existsSync(), isTrue);
        expect(await databaseFile.readAsBytes(), beforeOpen);
        expect(
          await const FlutterSecureStorage().read(key: 'db_encryption_key'),
          _wrongKey,
          reason: 'falha nao pode substituir a chave armazenada',
        );
        final diagnosticText = '$openingError\n${logs.join('\n')}';
        expect(diagnosticText, isNot(contains(_validKey)));
        expect(diagnosticText, isNot(contains(_wrongKey)));
      },
    );
  });

  group('contratos de erro e resolucao', () {
    test('MissingDatabaseKeyException identifica falha segura', () {
      final exception = MissingDatabaseKeyException(databaseFile.path);

      expect(exception.databasePath, databaseFile.path);
      expect(exception.toString(), contains('MissingDatabaseKeyException'));
      expect(exception.toString(), isNot(contains(_validKey)));
    });

    test('CipherValidationException mantem mensagem descritiva sem chave', () {
      final exception = CipherValidationException('cipher nao esta ativo');

      expect(exception.message, contains('cipher nao esta ativo'));
      expect(exception.toString(), contains('CipherValidationException'));
      expect(exception.toString(), isNot(contains(_validKey)));
    });

    test('resolveLocalDatabaseFile usa o diretorio de documentos', () async {
      final resolved = await resolveLocalDatabaseFile();

      expect(resolved.path, databaseFile.path);
    });
  });
}

Future<void> _createEncryptedSentinel(File file, String key) async {
  final database = TechReportLocalDatabase(
    openEncryptedDatabase(key, databaseFile: file),
  );
  await database.customStatement(
    'CREATE TABLE IF NOT EXISTS phase_20_2_key_safety '
    '(value TEXT NOT NULL)',
  );
  await database.customStatement(
    "INSERT INTO phase_20_2_key_safety(value) VALUES ('registro-preservado')",
  );
  await database.close();
}
