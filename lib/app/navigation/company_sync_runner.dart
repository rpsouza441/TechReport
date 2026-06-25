import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';

typedef ProcessCompanySyncQueue =
    Future<void> Function({
      required String empresaId,
      required String usuarioId,
      required bool retryFailed,
    });

typedef DownloadCompanyRats =
    Future<void> Function({
      required String empresaId,
      required String usuarioId,
      required String papel,
    });

typedef ReloadCompanyRatList = Future<void> Function();

enum CompanySyncStatus { success, failure, skipped }

class CompanySyncResult {
  const CompanySyncResult._({required this.status, this.message, this.error});

  const CompanySyncResult.success() : this._(status: CompanySyncStatus.success);

  const CompanySyncResult.skipped() : this._(status: CompanySyncStatus.skipped);

  const CompanySyncResult.failure({
    required String message,
    required Object error,
  }) : this._(
         status: CompanySyncStatus.failure,
         message: message,
         error: error,
       );

  final CompanySyncStatus status;
  final String? message;
  final Object? error;

  bool get isFailure => status == CompanySyncStatus.failure;
}

class CompanySyncRunner {
  CompanySyncRunner({
    required ProcessCompanySyncQueue processQueue,
    required DownloadCompanyRats downloadRemoteRats,
    required ReloadCompanyRatList reloadRatList,
  }) : _processQueue = processQueue,
       _downloadRemoteRats = downloadRemoteRats,
       _reloadRatList = reloadRatList;

  final ProcessCompanySyncQueue _processQueue;
  final DownloadCompanyRats _downloadRemoteRats;
  final ReloadCompanyRatList _reloadRatList;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<CompanySyncResult> sync(SessaoRemota? session) async {
    if (_isRunning) {
      return const CompanySyncResult.skipped();
    }

    final currentSession = session;
    final empresaId = currentSession?.empresaId;
    if (currentSession == null ||
        empresaId == null ||
        !currentSession.hasCompanyContext) {
      return const CompanySyncResult.skipped();
    }

    _isRunning = true;
    try {
      final papel =
          currentSession.papelEmpresa?.name ??
          currentSession.papelGlobal?.name ??
          'unknown';

      await _processQueue(
        empresaId: empresaId,
        usuarioId: currentSession.usuarioId,
        retryFailed: true,
      );
      await _downloadRemoteRats(
        empresaId: empresaId,
        usuarioId: currentSession.usuarioId,
        papel: papel,
      );
      await _reloadRatList();
      return const CompanySyncResult.success();
    } catch (error) {
      return CompanySyncResult.failure(
        message: companySyncErrorMessage(error),
        error: error,
      );
    } finally {
      _isRunning = false;
    }
  }
}

String companySyncErrorMessage(Object error) {
  final errorMsg = error.toString().toLowerCase();

  if (errorMsg.contains('connection') ||
      errorMsg.contains('socket') ||
      errorMsg.contains('timeout') ||
      errorMsg.contains('network')) {
    return 'Verifique sua conexão com a internet.';
  }

  if (errorMsg.contains('401') ||
      errorMsg.contains('unauthorized') ||
      errorMsg.contains('auth')) {
    return 'Sessão expirada. Entre novamente.';
  }

  if (errorMsg.contains('500') ||
      errorMsg.contains('server error') ||
      errorMsg.contains('internal')) {
    return 'Servidor indisponível. Tente mais tarde.';
  }

  return 'Não foi possível sincronizar. Tente novamente.';
}
