import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/shared/infra/security/local_pin_secret_store.dart';

class _FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  static const _sWrite = #write;
  static const _sRead = #read;
  static const _sDelete = #delete;
  static const _sDeleteAll = #deleteAll;
  static const _sReadAll = #readAll;
  static const _sContainsKey = #containsKey;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final member = invocation.memberName;
    final named = invocation.namedArguments;

    if (member == _sWrite) {
      final key = named[#key] as String;
      final value = named[#value] as String;
      _store[key] = value;
      return Future.value();
    }
    if (member == _sRead) {
      final key = named[#key] as String;
      return Future.value(_store[key]);
    }
    if (member == _sDelete) {
      final key = named[#key] as String;
      _store.remove(key);
      return Future.value();
    }
    if (member == _sDeleteAll) {
      _store.clear();
      return Future.value();
    }
    if (member == _sReadAll) {
      return Future.value(Map<String, String>.from(_store));
    }
    if (member == _sContainsKey) {
      final key = named[#key] as String;
      return Future.value(_store.containsKey(key));
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('LocalPinSecretStore', () {
    test('savePin does not store plain PIN', () async {
      final fake = _FakeSecureStorage();
      final store = LocalPinSecretStore(fake);

      await store.savePin('1234');

      final saved = await fake.read(key: 'local_pin');
      expect(saved, isNotNull);
      expect(saved, isNot(equals('1234')));
      expect(saved!.contains('1234'), isFalse);
    });

    test(
      'two saves of the same PIN produce different salts/verifiers',
      () async {
        final fake = _FakeSecureStorage();
        final store = LocalPinSecretStore(fake);

        await store.savePin('1234');
        final first = await fake.read(key: 'local_pin');

        await store.savePin('1234');
        final second = await fake.read(key: 'local_pin');

        expect(first, isNot(equals(second)));
      },
    );

    test('verifyPin accepts correct PIN', () async {
      final fake = _FakeSecureStorage();
      final store = LocalPinSecretStore(fake);

      await store.savePin('12345678');
      final result = await store.verifyPin('12345678');

      expect(result, isTrue);
    });

    test('verifyPin rejects wrong PIN', () async {
      final fake = _FakeSecureStorage();
      final store = LocalPinSecretStore(fake);

      await store.savePin('12345678');
      final result = await store.verifyPin('00000000');

      expect(result, isFalse);
    });

    test('verifyPin rejects invalid format without crash', () async {
      final fake = _FakeSecureStorage();
      final store = LocalPinSecretStore(fake);

      await fake.write(key: 'local_pin', value: 'not-a-valid-format');
      final result = await store.verifyPin('1234');

      expect(result, isFalse);
    });

    test('deletePin removes the verifier', () async {
      final fake = _FakeSecureStorage();
      final store = LocalPinSecretStore(fake);

      await store.savePin('1234');
      await store.deletePin();
      final saved = await fake.read(key: 'local_pin');

      expect(saved, isNull);
    });

    test('hasPin returns true when verifier exists', () async {
      final fake = _FakeSecureStorage();
      final store = LocalPinSecretStore(fake);

      await store.savePin('1234');
      final result = await store.hasPin();

      expect(result, isTrue);
    });

    test('hasPin returns false when no verifier exists', () async {
      final fake = _FakeSecureStorage();
      final store = LocalPinSecretStore(fake);

      final result = await store.hasPin();

      expect(result, isFalse);
    });

    test('migrates legacy plain PIN on first successful verify', () async {
      final fake = _FakeSecureStorage();
      final store = LocalPinSecretStore(fake);

      await fake.write(key: 'local_pin', value: '1234');
      final result = await store.verifyPin('1234');

      expect(result, isTrue);

      final verifier = await fake.read(key: 'local_pin');
      expect(verifier, startsWith('v1:pbkdf2-sha256:'));
    });
  });
}
