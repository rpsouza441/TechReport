class RemoteAuthException implements Exception {
  const RemoteAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
