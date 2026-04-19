import 'package:flutter/foundation.dart';

import '../../../signature/data/services/local_signature_asset_store.dart';
import '../../../signature/domain/entities/assinatura.dart';
import '../../../signature/domain/repositories/assinatura_repository.dart';
import '../../data/services/rat_pdf_share_service.dart';
import '../../domain/entities/rat.dart';
import '../../domain/repositories/rat_repository.dart';
import '../../domain/usecases/share_rat_locally.dart';

class RatFormViewModel extends ChangeNotifier {
  RatFormViewModel({
    required AssinaturaRepository assinaturaRepository,
    required LocalSignatureAssetStore localSignatureAssetStore,
    required RatPdfShareService ratPdfShareService,
    required RatRepository ratRepository,
    required ShareRatLocally shareRatLocally,
    Rat? initialRat,
  }) : _ratRepository = ratRepository,
       _assinaturaRepository = assinaturaRepository,
       _localSignatureAssetStore = localSignatureAssetStore,
       _ratPdfShareService = ratPdfShareService,
       _shareRatLocally = shareRatLocally,
       _initialRat = initialRat,
       ratId = initialRat?.id ?? _newRatId(),
       numero = initialRat?.numero ?? _newRatNumber(),
       clienteNome = initialRat?.clienteNome ?? '',
       descricao = initialRat?.descricao ?? '',
       status = initialRat?.status ?? RatStatus.draft,
       _isSaved = initialRat != null;

  final RatRepository _ratRepository;
  final AssinaturaRepository _assinaturaRepository;
  final LocalSignatureAssetStore _localSignatureAssetStore;
  final RatPdfShareService _ratPdfShareService;
  final ShareRatLocally _shareRatLocally;
  final Rat? _initialRat;

  final String ratId;
  final String numero;
  String clienteNome;
  String descricao;
  RatStatus status;

  bool _isSubmitting = false;
  bool _isSharing = false;
  bool _isSaved;
  String? _errorMessage;
  Assinatura? _assinatura;
  Uint8List? _signaturePreviewBytes;
  bool _isLoadingSignature = false;

  bool get isSubmitting => _isSubmitting;
  bool get isSharing => _isSharing;
  bool get isSaved => _isSaved;
  bool get hasSignature => _assinatura != null;
  bool get isLoadingSignature => _isLoadingSignature;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _initialRat != null;
  bool get shouldReloadOnClose => _isSaved;
  Uint8List? get signaturePreviewBytes => _signaturePreviewBytes;

  void setClienteNome(String value) {
    clienteNome = value;
    notifyListeners();
  }

  void setDescricao(String value) {
    descricao = value;
    notifyListeners();
  }

  void setStatus(RatStatus value) {
    status = value;
    notifyListeners();
  }

  String? validate() {
    if (clienteNome.trim().isEmpty) {
      return 'Informe o cliente.';
    }

    if (descricao.trim().isEmpty) {
      return 'Informe a descri\u00e7\u00e3o.';
    }

    return null;
  }

  Future<void> loadSignatureStatus() async {
    _isLoadingSignature = true;
    notifyListeners();

    final signatures = await _assinaturaRepository.listByRatId(ratId);
    signatures.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    _assinatura = signatures.isEmpty ? null : signatures.first;
    _signaturePreviewBytes = null;

    if (_assinatura case final assinatura?) {
      _signaturePreviewBytes = await _localSignatureAssetStore.read(
        assinatura.assetRef,
      );
    }

    _isLoadingSignature = false;
    notifyListeners();
  }

  Future<bool> save() async {
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final rat = Rat(
      id: ratId,
      authorId: _initialRat?.authorId ?? 'tec-local-001',
      ownerType: _initialRat?.ownerType ?? RatOwnerType.localTecnico,
      numero: numero,
      clienteNome: clienteNome.trim(),
      descricao: descricao.trim(),
      status: status,
      syncStatus: _initialRat?.syncStatus ?? RatSyncStatus.localOnly,
      createdAt: _initialRat?.createdAt ?? now,
      updatedAt: now,
      deletedAt: _initialRat?.deletedAt,
    );

    await _ratRepository.save(rat);

    _isSubmitting = false;
    _isSaved = true;
    notifyListeners();
    return true;
  }

  Future<void> submit() async {
    await save();
  }

  Future<bool> saveSignature(Uint8List bytes) async {
    final saved = await save();
    if (!saved) {
      return false;
    }

    final currentSignatures = await _assinaturaRepository.listByRatId(ratId);
    for (final assinatura in currentSignatures) {
      if (assinatura.storageMode == StorageMode.localFile) {
        await _localSignatureAssetStore.delete(assinatura.assetRef);
      }
      await _assinaturaRepository.delete(assinatura.id);
    }

    final now = DateTime.now();
    final assinaturaId = 'assinatura-${now.microsecondsSinceEpoch}';
    final assetRef = await _localSignatureAssetStore.savePng(
      assinaturaId: assinaturaId,
      bytes: bytes,
    );

    final assinatura = Assinatura(
      id: assinaturaId,
      ratId: ratId,
      storageMode: StorageMode.localFile,
      assetRef: assetRef,
      createdAt: now,
      updatedAt: now,
    );

    await _assinaturaRepository.save(assinatura);
    _assinatura = assinatura;
    _signaturePreviewBytes = bytes;
    notifyListeners();
    return true;
  }

  Future<bool> sharePdf() async {
    final saved = await save();
    if (!saved) {
      return false;
    }

    _isSharing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final shareData = await _shareRatLocally(ratId);
      if (!shareData.success) {
        _errorMessage = shareData.errorMessage;
        return false;
      }

      await _ratPdfShareService.share(shareData);
      return true;
    } catch (_) {
      _errorMessage = 'Nao foi possivel compartilhar o PDF.';
      return false;
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }
}

String _newRatId() {
  return 'rat-${DateTime.now().microsecondsSinceEpoch}';
}

String _newRatNumber() {
  return 'RAT-${DateTime.now().millisecondsSinceEpoch}';
}
