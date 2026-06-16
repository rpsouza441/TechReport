import 'dart:async';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/services/rat_sync_coordinator.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';

/// Coordinates sync operations after save/signature/delete.
///
/// Single responsibility: sync coordination.
/// Extracted from RatFormViewModel to reduce coupling and improve testability.
class RatSyncHandler {
  RatSyncHandler({
    required RatSyncCoordinator? syncCoordinator,
    required DownloadRemoteRats? downloadRemoteRats,
    required String? empresaId,
    required String? usuarioId,
    required String? papel,
  })  : _syncCoordinator = syncCoordinator,
        _downloadRemoteRats = downloadRemoteRats,
        _empresaId = empresaId,
        _usuarioId = usuarioId,
        _papel = papel;

  final RatSyncCoordinator? _syncCoordinator;
  final DownloadRemoteRats? _downloadRemoteRats;
  final String? _empresaId;
  final String? _usuarioId;
  final String? _papel;

  /// Syncs after RAT save.
  Future<void> syncAfterSave(Rat rat) async {
    if (_syncCoordinator == null || _empresaId == null || _usuarioId == null) {
      return;
    }

    await _syncCoordinator.syncAfterSave(
      rat: rat,
      empresaId: _empresaId!,
      usuarioId: _usuarioId!,
    );
    _downloadAfterSync();
  }

  /// Syncs after RAT deletion.
  Future<void> syncAfterDelete(Rat rat) async {
    if (_syncCoordinator == null || _empresaId == null || _usuarioId == null) {
      return;
    }

    await _syncCoordinator.syncAfterDelete(
      rat: rat,
      empresaId: _empresaId!,
      usuarioId: _usuarioId!,
    );
    _downloadAfterSync();
  }

  /// Syncs after signature save.
  Future<void> syncAfterSignature(Assinatura assinatura) async {
    if (_syncCoordinator == null || _empresaId == null || _usuarioId == null) {
      return;
    }

    await _syncCoordinator.syncAfterSignature(
      assinatura: assinatura,
      empresaId: _empresaId!,
      usuarioId: _usuarioId!,
      ratId: assinatura.ratId,
    );
    _downloadAfterSync();
  }

  /// Triggers background download of remote RATs after sync completes.
  void _downloadAfterSync() {
    if (_downloadRemoteRats == null || _empresaId == null || _usuarioId == null) {
      return;
    }

    unawaited(_callDownloadRemoteRats());
  }

  Future<void> _callDownloadRemoteRats() async {
    try {
      await _downloadRemoteRats!.call(
        empresaId: _empresaId!,
        usuarioId: _usuarioId!,
        papel: _papel ?? 'unknown',
      );
    } catch (e, st) {
      // RAT local already saved; retry will be triggered by RAT list.
      assert(false, "Error: $e$st");
    }
  }
}
