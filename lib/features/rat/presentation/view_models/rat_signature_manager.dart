import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';

/// Manages signature loading, saving, and preview.
///
/// Single responsibility: signature lifecycle.
/// Extracted from RatFormViewModel to reduce coupling and improve testability.
class RatSignatureManager extends ChangeNotifier {
  RatSignatureManager({
    required AssinaturaRepository assinaturaRepository,
    required LocalSignatureAssetStore localSignatureAssetStore,
    required String ratId,
    required void Function(String) onError,
    EnqueueAssinaturaSync? enqueueAssinaturaSync,
  })  : _assinaturaRepository = assinaturaRepository,
        _localSignatureAssetStore = localSignatureAssetStore,
        _ratId = ratId,
        _onError = onError,
        _enqueueAssinaturaSync = enqueueAssinaturaSync;

  static const maxSignatureBytes = 1 * 1024 * 1024; // 1 MB

  final AssinaturaRepository _assinaturaRepository;
  final LocalSignatureAssetStore _localSignatureAssetStore;
  final String _ratId;
  final void Function(String) _onError;
  final EnqueueAssinaturaSync? _enqueueAssinaturaSync;

  Assinatura? _assinatura;
  Uint8List? _signaturePreviewBytes;
  bool _isLoadingSignature = false;
  bool _isSavingSignature = false;

  bool get hasSignature => _assinatura != null;
  bool get isLoadingSignature => _isLoadingSignature;
  bool get isSavingSignature => _isSavingSignature;
  Uint8List? get signaturePreviewBytes => _signaturePreviewBytes;
  Assinatura? get assinatura => _assinatura;

  /// Clears the signature preview (e.g., after reopening for correction).
  void clearPreview() {
    _signaturePreviewBytes = null;
    notifyListeners();
  }

  /// Load signature status and preview bytes.
  Future<void> loadSignatureStatus() async {
    _isLoadingSignature = true;
    notifyListeners();

    try {
      final signatures = await _assinaturaRepository.listByRatId(_ratId);
      signatures.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _assinatura = signatures.isEmpty ? null : signatures.first;
      _signaturePreviewBytes = null;

      if (_assinatura case final assinatura?) {
        if (assinatura.storageMode == StorageMode.inlineBinary) {
          _signaturePreviewBytes =
              await _assinaturaRepository.readBytes(assinatura.id);
        } else if (assinatura.storageMode == StorageMode.localFile) {
          _signaturePreviewBytes = await _localSignatureAssetStore.read(
            assinatura.assetRef,
          );
        }
      }
    } catch (e, st) {
      debugPrint("Error loading signature: $e$st");
      _assinatura = null;
      _signaturePreviewBytes = null;
    }

    _isLoadingSignature = false;
    notifyListeners();
  }

  /// Saves signature bytes, replacing any existing signature.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> saveSignature(
    Uint8List bytes, {
    required String empresaId,
    required String usuarioId,
    required bool hasCompanyContext,
    required Future<void> Function(String, String) syncAfterSignature,
    required Future<void> Function(String, String) downloadRemoteRatsAfterSync,
    required Future<bool> Function({required bool enqueueSync}) saveRat,
  }) async {
    if (bytes.length > maxSignatureBytes) {
      _onError('Assinatura muito grande. Use um canvas menor.');
      notifyListeners();
      return false;
    }

    _isSavingSignature = true;
    notifyListeners();

    try {
      // Save the RAT first (without enqueuing sync)
      final saved = await saveRat(enqueueSync: false);
      if (!saved) {
        _isSavingSignature = false;
        notifyListeners();
        return false;
      }

      // Delete existing signatures
      final currentSignatures =
          await _assinaturaRepository.listByRatId(_ratId);
      for (final assinatura in currentSignatures) {
        // Fire-and-forget remote delete before removing locally
        if (hasCompanyContext) {
          unawaited(_enqueueAssinaturaSync?.delete(
            assinatura,
            empresaId: empresaId,
            usuarioId: usuarioId,
            ratId: _ratId,
          ));
        }

        if (assinatura.storageMode == StorageMode.localFile) {
          await _localSignatureAssetStore.delete(assinatura.assetRef);
        }
        await _assinaturaRepository.delete(assinatura.id);
      }

      // Create new signature
      final now = DateTime.now();
      final assinaturaId = 'assinatura-${now.microsecondsSinceEpoch}';

      await _assinaturaRepository.saveBytes(
        assinaturaId: assinaturaId,
        bytes: bytes,
        assetRef: 'signatures/$assinaturaId.png',
        ratId: _ratId,
      );

      final assinatura = Assinatura(
        id: assinaturaId,
        ratId: _ratId,
        storageMode: StorageMode.inlineBinary,
        assetRef: 'signatures/$assinaturaId.png',
        data: bytes,
        sizeBytes: bytes.length,
        sha256: null,
        mimeType: 'image/png',
        createdAt: now,
        updatedAt: now,
      );

      _assinatura = assinatura;
      _signaturePreviewBytes = bytes;
      _isSavingSignature = false;
      notifyListeners();

      // Sync signature to remote if in company mode
      if (hasCompanyContext) {
        await syncAfterSignature(empresaId, usuarioId);
        await downloadRemoteRatsAfterSync(empresaId, usuarioId);
      }

      return true;
    } catch (e, st) {
      debugPrint("Error saving signature: $e$st");
      _isSavingSignature = false;
      notifyListeners();
      return false;
    }
  }
}
