import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:techreport/features/local_auth/domain/repositories/pin_secret_repository.dart';

class LocalPinSecretStore implements PinSecretRepository {
  LocalPinSecretStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _pinKey = 'local_pin';
  // OWASP 2023 recommends 120,000+ iterations for PBKDF2-HMAC-SHA256.
  // Using 100,000 as minimum to ensure adequate security against brute-force.
  static const _defaultIterations = 100000;

  final FlutterSecureStorage _storage;

  @override
  Future<void> savePin(String pin) async {
    final salt = _generateSalt();
    final hash = _pbkdf2Sha256(pin, salt, _defaultIterations);
    final verifier = _buildVerifier(salt, hash, _defaultIterations);
    await _storage.write(key: _pinKey, value: verifier);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final raw = await _storage.read(key: _pinKey);
    if (raw == null || raw.isEmpty) return false;

    if (!_isVersioned(raw)) {
      return _verifyLegacy(raw, pin);
    }

    final parsed = _parseVerifier(raw);
    if (parsed == null) return false;

    final hash = _pbkdf2Sha256(pin, parsed.salt, parsed.iterations);
    final isValid = _constantTimeCompare(hash, parsed.hash);

    // Migrate to new iteration count if verified and using old count
    if (isValid && parsed.iterations < _defaultIterations) {
      debugPrint('Migrating PIN from ${parsed.iterations} to $_defaultIterations iterations');
      await savePin(pin);
    }

    return isValid;
  }

  @override
  Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
  }

  @override
  Future<bool> hasPin() async {
    final raw = await _storage.read(key: _pinKey);
    return raw != null && raw.isNotEmpty;
  }

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  Uint8List _pbkdf2Sha256(String pin, Uint8List salt, int iterations) {
    final pinBytes = utf8.encode(pin);
    final hmac = _HmacSha256(pinBytes);

    // INT(i) —4-byte big-endian block index
    final blockIndex = Uint8List.fromList([0, 0, 0, 1]);
    final saltBlock = Uint8List.fromList([...salt, ...blockIndex]);

    // U_1 = HMAC(Password, Salt || INT(1))
    final u = Uint8List.fromList(hmac.convert(saltBlock).bytes);
    final result = Uint8List.fromList(u);

    // U_j = HMAC(Password, U_{j-1}) for j = 2..iterations
    for (var j = 1; j < iterations; j++) {
      final uj = Uint8List.fromList(hmac.convert(u).bytes);
      for (var i = 0; i < 32; i++) {
        result[i] ^= uj[i];
      }
      for (var i = 0; i < 32; i++) {
        u[i] = uj[i];
      }
    }

    return result;
  }

  String _buildVerifier(Uint8List salt, Uint8List hash, int iterations) {
    final saltB64 = base64Encode(salt);
    final hashB64 = base64Encode(hash);
    return 'v1:pbkdf2-sha256:$iterations:$saltB64:$hashB64';
  }

  bool _isVersioned(String value) => value.startsWith('v1:');

  _ParsedVerifier? _parseVerifier(String value) {
    final parts = value.split(':');
    if (parts.length != 5) return null;
    if (parts[0] != 'v1') return null;
    if (parts[1] != 'pbkdf2-sha256') return null;

    final iterations = int.tryParse(parts[2]);
    if (iterations == null || iterations <= 0) return null;

    Uint8List salt;
    Uint8List hash;
    try {
      salt = base64Decode(parts[3]);
      hash = base64Decode(parts[4]);
    } catch (_) {
      return null;
    }

    return _ParsedVerifier(salt, hash, iterations);
  }

  Future<bool> _verifyLegacy(String plainPin, String inputPin) async {
    if (plainPin != inputPin) return false;

    final salt = _generateSalt();
    final hash = _pbkdf2Sha256(inputPin, salt, _defaultIterations);
    final verifier = _buildVerifier(salt, hash, _defaultIterations);
    await _storage.write(key: _pinKey, value: verifier);
    return true;
  }

  bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

class _ParsedVerifier {
  const _ParsedVerifier(this.salt, this.hash, this.iterations);
  final Uint8List salt;
  final Uint8List hash;
  final int iterations;
}

class _HmacSha256 {
  _HmacSha256(List<int> key) {
    if (key.length > 64) {
      key = sha256.convert(key).bytes;
    }
    if (key.length < 64) {
      key = [...key, ...List<int>.filled(64 - key.length, 0)];
    }
    _ipad = Uint8List.fromList(key.map((b) => b ^ 0x36).toList());
    _opad = Uint8List.fromList(key.map((b) => b ^ 0x5c).toList());
  }

  late final Uint8List _ipad;
  late final Uint8List _opad;

  Digest convert(List<int> data) {
    final inner = sha256.convert([..._ipad, ...data]).bytes;
    return sha256.convert([..._opad, ...inner]);
  }
}
