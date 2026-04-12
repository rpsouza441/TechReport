abstract class PinSecretRepository {
  Future<void> savePin(String pin);
  Future<bool> verifyPin(String pin);
}
