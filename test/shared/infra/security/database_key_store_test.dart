import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/shared/infra/security/database_key_store.dart';

class _FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  static const _sWrite = #write;
  static const _sRead = #read;
  static const _sDelete = #delete;
  static const _sDeleteAll = #deleteAll;

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
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('DatabaseKeyStore', () {
    test('readKey returns null when no key exists', () async {
      final store = DatabaseKeyStore(_FakeSecureStorage());

      final key = await store.readKey();

      expect(key, isNull);
    });

    test('createKey stores a 32-byte key encoded as 64 hex chars', () async {
      final fake = _FakeSecureStorage();
      final store = DatabaseKeyStore(fake);

      final key = await store.createKey();

      expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(await fake.read(key: 'db_encryption_key'), equals(key));
    });

    test('getOrCreateKey reuses an existing key', () async {
      final fake = _FakeSecureStorage();
      await fake.write(key: 'db_encryption_key', value: 'a' * 64);
      final store = DatabaseKeyStore(fake);

      final key = await store.getOrCreateKey();

      expect(key, equals('a' * 64));
    });

    test('getOrCreateKey creates only once', () async {
      final fake = _FakeSecureStorage();
      final store = DatabaseKeyStore(fake);

      final first = await store.getOrCreateKey();
      final second = await store.getOrCreateKey();

      expect(second, equals(first));
    });

    test('deleteKey removes the stored key', () async {
      final fake = _FakeSecureStorage();
      final store = DatabaseKeyStore(fake);

      await store.createKey();
      await store.deleteKey();

      expect(await store.readKey(), isNull);
    });
  });
}
