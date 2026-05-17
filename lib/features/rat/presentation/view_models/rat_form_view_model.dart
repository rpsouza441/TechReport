import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_rat_sync.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';
import 'package:techreport/features/sync/domain/usecases/process_sync_queue.dart';
import 'package:uuid/uuid.dart';

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
    SessaoRemota? remoteSession,
    EnqueueRatSync? enqueueRatSync,
    ProcessSyncQueue? processSyncQueue,
    DownloadRemoteRats? downloadRemoteRats,
  }) : _ratRepository = ratRepository,
       _assinaturaRepository = assinaturaRepository,
       _localSignatureAssetStore = localSignatureAssetStore,
       _ratPdfShareService = ratPdfShareService,
       _shareRatLocally = shareRatLocally,
       _initialRat = initialRat,
       ratId = initialRat?.id ?? _newRatId(),
       numero = initialRat?.numero ?? _newRatNumber(),
       clienteNome = initialRat?.clienteNome ?? '',
       responsavelRecebimento = initialRat?.responsavelRecebimento ?? '',
       dataVisita = initialRat?.dataVisita,
       horarioInicioAtendimento = initialRat?.horarioInicioAtendimento ?? '',
       horarioTerminoAtendimento = initialRat?.horarioTerminoAtendimento ?? '',
       descricao = initialRat?.descricao ?? '',
       equipamentoMovimentoTipo =
           initialRat?.equipamentoMovimentoTipo ??
           EquipamentoMovimentoTipo.nenhum,
       equipamentoDescricao = initialRat?.equipamentoDescricao ?? '',
       equipamentoObservacao = initialRat?.equipamentoObservacao ?? '',
       status = initialRat?.status ?? RatStatus.draft,
       _remoteSession = remoteSession,
       _processSyncQueue = processSyncQueue,
       _enqueueRatSync = enqueueRatSync,
       _downloadRemoteRats = downloadRemoteRats,
       _isSaved = initialRat != null;

  final RatRepository _ratRepository;
  final AssinaturaRepository _assinaturaRepository;
  final LocalSignatureAssetStore _localSignatureAssetStore;
  final RatPdfShareService _ratPdfShareService;
  final ShareRatLocally _shareRatLocally;
  final Rat? _initialRat;
  final SessaoRemota? _remoteSession;
  final EnqueueRatSync? _enqueueRatSync;
  final ProcessSyncQueue? _processSyncQueue;
  final DownloadRemoteRats? _downloadRemoteRats;
  final String ratId;
  final String numero;
  String clienteNome;
  String responsavelRecebimento;
  DateTime? dataVisita;
  String horarioInicioAtendimento;
  String horarioTerminoAtendimento;
  String descricao;
  EquipamentoMovimentoTipo equipamentoMovimentoTipo;
  String equipamentoDescricao;
  String equipamentoObservacao;
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
  bool get canDelete {
    final initialRat = _initialRat;
    if (initialRat == null) {
      return false;
    }

    final remoteSession = _remoteSession;
    if (remoteSession == null) {
      return true;
    }

    return initialRat.tecnicoId == remoteSession.tecnicoId;
  }

  bool get canEdit {
    final initialRat = _initialRat;
    if (initialRat == null) {
      return true;
    }

    final remoteSession = _remoteSession;
    if (remoteSession == null) {
      return true;
    }

    return initialRat.tecnicoId == remoteSession.tecnicoId;
  }

  void setClienteNome(String value) {
    clienteNome = value;
    notifyListeners();
  }

  void setResponsavelRecebimento(String value) {
    responsavelRecebimento = value;
    notifyListeners();
  }

  void setDataVisita(DateTime? value) {
    dataVisita = value;
    notifyListeners();
  }

  void setHorarioInicioAtendimento(String value) {
    horarioInicioAtendimento = value;
    notifyListeners();
  }

  void setHorarioTerminoAtendimento(String value) {
    horarioTerminoAtendimento = value;
    notifyListeners();
  }

  void setDescricao(String value) {
    descricao = value;
    notifyListeners();
  }

  void setEquipamentoMovimentoTipo(EquipamentoMovimentoTipo value) {
    equipamentoMovimentoTipo = value;
    notifyListeners();
  }

  void setEquipamentoDescricao(String value) {
    equipamentoDescricao = value;
    notifyListeners();
  }

  void setEquipamentoObservacao(String value) {
    equipamentoObservacao = value;
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

    if (responsavelRecebimento.trim().isEmpty) {
      return 'Informe o responsavel pelo recebimento.';
    }

    if (dataVisita == null) {
      return 'Informe a data da visita.';
    }

    if (!_isValidHour(horarioInicioAtendimento)) {
      return 'Informe o horario de inicio no formato HH:mm.';
    }

    if (!_isValidHour(horarioTerminoAtendimento)) {
      return 'Informe o horario de termino no formato HH:mm.';
    }

    if (descricao.trim().isEmpty) {
      return 'Informe a descricao.';
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

  Future<bool> save({bool enqueueSync = true}) async {
    if (!canEdit) {
      _errorMessage = 'Este RAT pertence a outro tecnico.';
      notifyListeners();
      return false;
    }

    final validationError = validate();
    final isCompanyMode = _remoteSession != null;

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
      authorId:
          _initialRat?.authorId ?? _remoteSession?.tecnicoId ?? 'tec-local-001',
      empresaId: _initialRat?.empresaId ?? _remoteSession?.empresaId,
      usuarioId: _initialRat?.usuarioId ?? _remoteSession?.usuarioId,
      tecnicoId: _initialRat?.tecnicoId ?? _remoteSession?.tecnicoId,
      ownerType:
          _initialRat?.ownerType ??
          (isCompanyMode
              ? RatOwnerType.companyTecnico
              : RatOwnerType.localTecnico),
      numero: numero,
      clienteNome: clienteNome.trim(),
      responsavelRecebimento: responsavelRecebimento.trim(),
      dataVisita: dataVisita,
      horarioInicioAtendimento: horarioInicioAtendimento.trim(),
      horarioTerminoAtendimento: horarioTerminoAtendimento.trim(),
      descricao: descricao.trim(),
      equipamentoMovimentoTipo: equipamentoMovimentoTipo,
      equipamentoDescricao: equipamentoDescricao.trim().isEmpty
          ? null
          : equipamentoDescricao.trim(),
      equipamentoObservacao: equipamentoObservacao.trim().isEmpty
          ? null
          : equipamentoObservacao.trim(),
      status: status,
      syncStatus: isCompanyMode
          ? RatSyncStatus.pendingSync
          : RatSyncStatus.localOnly,
      createdAt: _initialRat?.createdAt ?? now,
      updatedAt: now,
      deletedAt: _initialRat?.deletedAt,
    );

    try {
      await _ratRepository.save(rat);
      if (enqueueSync && isCompanyMode) {
        await _enqueueRatSync?.upsert(rat);
        _syncInBackground(_remoteSession.empresaId);
      }
    } catch (_) {
      _isSubmitting = false;
      _errorMessage = 'Nao foi possivel salvar o RAT.';
      notifyListeners();
      return false;
    }

    _isSubmitting = false;
    _isSaved = true;
    notifyListeners();
    return true;
  }

  Future<void> submit() async {
    await save();
  }

  Future<bool> deleteRat() async {
    final initialRat = _initialRat;
    if (initialRat == null || !canDelete) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final isCompanyMode = _remoteSession != null;
    final deletedRat = initialRat.copyWith(
      syncStatus: isCompanyMode
          ? RatSyncStatus.pendingSync
          : RatSyncStatus.localOnly,
      updatedAt: now,
      deletedAt: now,
    );

    try {
      await _ratRepository.save(deletedRat);
      if (isCompanyMode) {
        await _enqueueRatSync?.delete(deletedRat);
        _syncInBackground(_remoteSession.empresaId);
      }
    } catch (_) {
      _isSubmitting = false;
      _errorMessage = 'Nao foi possivel excluir o RAT.';
      notifyListeners();
      return false;
    }

    _isSubmitting = false;
    _isSaved = true;
    notifyListeners();
    return true;
  }

  void _syncInBackground(String empresaId) {
    final processSyncQueue = _processSyncQueue;
    final usuarioId = _remoteSession?.usuarioId;

    if (processSyncQueue == null || usuarioId == null) {
      return;
    }

    unawaited(() async {
      try {
        await processSyncQueue.call(empresaId: empresaId, usuarioId: usuarioId);
        await _downloadRemoteRats?.call(empresaId: empresaId);
      } catch (_) {
        // RAT local continua salvo; retry manual fica pela lista.
      }
    }());
  }

  Future<bool> saveSignature(Uint8List bytes) async {
    final saved = await save(enqueueSync: false);
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
    final saved = await save(enqueueSync: false);
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
  return const Uuid().v4();
}

String _newRatNumber() {
  return 'RAT-${DateTime.now().microsecondsSinceEpoch}';
}

bool _isValidHour(String value) {
  return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value.trim());
}
