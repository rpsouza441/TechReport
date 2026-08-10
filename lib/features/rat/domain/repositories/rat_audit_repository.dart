import 'package:techreport/features/rat/domain/entities/rat_audit_event.dart';

abstract class RatAuditRepository {
  Future<RatAuditPage> listForRat({
    required String ratId,
    RatAuditCursor? cursor,
    int limit = 20,
  });
}

sealed class RatAuditException implements Exception {
  const RatAuditException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

final class RatAuditAccessDeniedException extends RatAuditException {
  const RatAuditAccessDeniedException([
    super.message = 'Acesso negado ao historico da RAT.',
    super.cause,
  ]);
}

final class RatAuditOfflineException extends RatAuditException {
  const RatAuditOfflineException([
    super.message = 'Historico da RAT indisponivel sem conexao.',
    super.cause,
  ]);
}

final class RatAuditLoadException extends RatAuditException {
  const RatAuditLoadException([
    super.message = 'Nao foi possivel carregar o historico da RAT.',
    super.cause,
  ]);
}
