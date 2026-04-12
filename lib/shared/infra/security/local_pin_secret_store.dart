import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:techreport/features/local_auth/domain/repositories/pin_secret_repository.dart';

class LocalPinSecretStore implements PinSecretRepository {
  LocalPinSecretStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _pinKey = 'local_pin';

  final FlutterSecureStorage _storage;

  @override
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final savedPin = await _storage.read(key: _pinKey);
    return savedPin == pin;
  }
}
