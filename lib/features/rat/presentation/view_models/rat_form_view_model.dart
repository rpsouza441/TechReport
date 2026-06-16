import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/permissions/rat_permissions.dart';
import 'package:techreport/features/rat/domain/services/rat_sync_coordinator.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:uuid/uuid.dart';

class RatFormViewModel extends ChangeNotifier {
  RatFormViewModel({
    required AssinaturaRepository assinaturaRepository,
    required LocalSignatureAssetStore localSignatureAssetStore,
    required RatPdfShareService ratPdfShareService,
    required RatRepository ratRepository,
    required ShareRatLocally shareRatLocally,
    Rat? initialRat,
    SessaoRemota? remoteSession,
    EnqueueAssinaturaSync? enqueueAssinaturaSync,
    RatSyncCoordinator? syncCoordinator,
    DownloadRemoteRats? downloadRemoteRats,
    SupabaseClientFactory? supabaseClientFactory,
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
       responsavelDocumento = initialRat?.responsavelDocumento ?? '',
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
       ultimoAlteradorUserId = initialRat?.ultimoAlteradorUserId,
       ultimaAlteracaoEm = initialRat?.ultimaAlteracaoEm,
       reabertaParaCorrecaoEm = initialRat?.reabertaParaCorrecaoEm,
       reabertaParaCorrecaoPorUserId =
           initialRat?.reabertaParaCorrecaoPorUserId,
       motivoReabertura = initialRat?.motivoReabertura,
       assinaturaInvalidadaEm = initialRat?.assinaturaInvalidadaEm,
       assinaturaInvalidadaPorUserId =
           initialRat?.assinaturaInvalidadaPorUserId,
       _remoteSession = remoteSession,
       _enqueueAssinaturaSync = enqueueAssinaturaSync,
       _syncCoordinator = syncCoordinator,
       _downloadRemoteRats = downloadRemoteRats,
       _supabaseClientFactory = supabaseClientFactory,
       _isSaved = initialRat != null;

  static const _permissions = RatPermissions();
  /// 1 MB maximum signature size.
  static const maxSignatureBytes = 1 * 1024 * 1024;

  final RatRepository _ratRepository;
  final AssinaturaRepository _assinaturaRepository;
  final LocalSignatureAssetStore _localSignatureAssetStore;
  final RatPdfShareService _ratPdfShareService;
  final ShareRatLocally _shareRatLocally;
  final Rat? _initialRat;
  final SessaoRemota? _remoteSession;
  final EnqueueAssinaturaSync? _enqueueAssinaturaSync;
  final RatSyncCoordinator? _syncCoordinator;
  final DownloadRemoteRats? _downloadRemoteRats;
  final SupabaseClientFactory? _supabaseClientFactory;
  final String ratId;
  final String numero;
  String clienteNome;
  String responsavelRecebimento;
  String responsavelDocumento;
  DateTime? dataVisita;
  String horarioInicioAtendimento;
  String horarioTerminoAtendimento;
  String descricao;
  EquipamentoMovimentoTipo equipamentoMovimentoTipo;
  String equipamentoDescricao;
  String equipamentoObservacao;
  RatStatus status;
  String? ultimoAlteradorUserId;
  DateTime? ultimaAlteracaoEm;
  DateTime? reabertaParaCorrecaoEm;
  String? reabertaParaCorrecaoPorUserId;
  String? motivoReabertura;
  DateTime? assinaturaInvalidadaEm;
  String? assinaturaInvalidadaPorUserId;

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
  bool get hasValidSignature => _assinatura != null && !isSignaturePending;
  bool get isLoadingSignature => _isLoadingSignature;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _initialRat != null;
  bool get shouldReloadOnClose => _isSaved;
  Uint8List? get signaturePreviewBytes => _signaturePreviewBytes;
  bool get isSignaturePending {
    final invalidatedAt = assinaturaInvalidadaEm;
    if (invalidatedAt == null) {
      return false;
    }

    final assinatura = _assinatura;
    return assinatura == null || !assinatura.updatedAt.isAfter(invalidatedAt);
  }

  bool get isLockedUntilReopen {
    if (!hasValidSignature) {
      return false;
    }

    return canReopenForCorrection;
  }

  bool get canEditFields => canEdit && !isLockedUntilReopen;

  bool get canPreviewPdf => _initialRat != null || _isSaved || canEditFields;

  /// True quando o formulário deve ser exibido em modo somente leitura.
  ///
  /// Técnico não-dono (que não é gerente/admin) abre RAT de outro em modo
  /// somente leitura — campos desabilitados, sem botão salvar.
  bool get isReadOnly {
    final initialRat = _initialRat;
    if (initialRat == null) return false;
    return !_permissions.canEdit(initialRat, _remoteSession);
  }

  bool get canDelete {
    final initialRat = _initialRat;
    if (initialRat == null) return false;
    return _permissions.canDelete(initialRat, _remoteSession);
  }

  bool get canEdit {
    final initialRat = _initialRat;
    if (initialRat == null) return true;
    return _permissions.canEdit(initialRat, _remoteSession);
  }

  bool get canReopenForCorrection {
    final initialRat = _initialRat;
    if (initialRat == null) {
      return false;
    }

    return _permissions.canReopenForCorrection(
      _ratWithCurrentAudit(initialRat),
      _remoteSession,
    );
  }

  void setClienteNome(String value) {
    clienteNome = value;
    notifyListeners();
  }

  void setResponsavelRecebimento(String value) {
    responsavelRecebimento = value;
    notifyListeners();
  }

  void setResponsavelDocumento(String value) {
    responsavelDocumento = value;
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

  String? empresaNome;

  String? get tecnicoNome => _remoteSession?.nome;

  String? validate() {
    if (clienteNome.trim().isEmpty) {
      return 'Informe o cliente.';
    }

    if (responsavelRecebimento.trim().isEmpty) {
      return 'Informe o responsável pelo recebimento.';
    }

    if (dataVisita == null) {
      return 'Informe a data da visita.';
    }

    final normalizedStart = _normalizeHour(horarioInicioAtendimento);
    if (normalizedStart == null) {
      return 'Informe o horário de início no formato HH:mm.';
    }

    if (!_isHourInRange(horarioInicioAtendimento)) {
      return 'Horário de início inválido. Use 00:00 até 23:59.';
    }

    final normalizedEnd = _normalizeHour(horarioTerminoAtendimento);
    if (normalizedEnd == null) {
      return 'Informe o horário de término no formato HH:mm.';
    }

    if (!_isHourInRange(horarioTerminoAtendimento)) {
      return 'Horário de término inválido. Use 00:00 até 23:59.';
    }

    if (!_isEndAfterStart(normalizedStart, normalizedEnd)) {
      return 'Horário de término precisa ser depois do início.';
    }

    if (descricao.trim().isEmpty) {
      return 'Informe a descrição.';
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
      if (assinatura.storageMode == StorageMode.inlineBinary) {
        _signaturePreviewBytes = await _assinaturaRepository.readBytes(
          assinatura.id,
        );
      } else if (assinatura.storageMode == StorageMode.localFile) {
        _signaturePreviewBytes = await _localSignatureAssetStore.read(
          assinatura.assetRef,
        );
      }
    }

    _isLoadingSignature = false;
    notifyListeners();
  }

  /// Constrói o objeto Rat a partir dos campos do formulário.
  Rat _buildRatForSave({
    required bool isCompanyMode,
    required SessaoRemota? remoteSession,
    required DateTime now,
  }) {
    final auditUserId = isCompanyMode
        ? remoteSession!.usuarioId
        : ultimoAlteradorUserId;
    final auditUpdatedAt = isCompanyMode ? now : ultimaAlteracaoEm;

    return Rat(
      id: ratId,
      authorId:
          _initialRat?.authorId ?? remoteSession?.tecnicoId ?? 'tec-local-001',
      empresaId: _initialRat?.empresaId ?? remoteSession?.empresaId,
      usuarioId: _initialRat?.usuarioId ?? remoteSession?.usuarioId,
      tecnicoId: _initialRat?.tecnicoId ?? remoteSession?.tecnicoId,
      ownerType:
          _initialRat?.ownerType ??
          (isCompanyMode
              ? RatOwnerType.companyTecnico
              : RatOwnerType.localTecnico),
      numero: numero,
      clienteNome: clienteNome.trim(),
      responsavelRecebimento: responsavelRecebimento.trim(),
      responsavelDocumento: _optionalText(responsavelDocumento),
      dataVisita: dataVisita,
      horarioInicioAtendimento: _normalizeHour(horarioInicioAtendimento)!,
      horarioTerminoAtendimento: _normalizeHour(horarioTerminoAtendimento)!,
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
      ultimoAlteradorUserId: auditUserId,
      ultimaAlteracaoEm: auditUpdatedAt,
      reabertaParaCorrecaoEm: reabertaParaCorrecaoEm,
      reabertaParaCorrecaoPorUserId: reabertaParaCorrecaoPorUserId,
      motivoReabertura: motivoReabertura,
      assinaturaInvalidadaEm: assinaturaInvalidadaEm,
      assinaturaInvalidadaPorUserId: assinaturaInvalidadaPorUserId,
    );
  }

  Future<bool> save({bool enqueueSync = true}) async {
    if (!canEditFields) {
      _errorMessage = isLockedUntilReopen
          ? 'Reabra este RAT para correção antes de editar.'
          : 'Este RAT pertence a outro técnico.';
      notifyListeners();
      return false;
    }

    final validationError = validate();
    final remoteSession = _remoteSession;
    final isCompanyMode = remoteSession?.hasCompanyContext ?? false;
    final companyEmpresaId = isCompanyMode ? remoteSession!.empresaId! : null;

    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final rat = _buildRatForSave(
      isCompanyMode: isCompanyMode,
      remoteSession: remoteSession,
      now: now,
    );

    try {
      await _ratRepository.save(rat);
      if (enqueueSync && isCompanyMode) {
        await _syncCoordinator?.syncAfterSave(
          rat: rat,
          empresaId: companyEmpresaId!,
          usuarioId: remoteSession!.usuarioId,
        );
        _downloadRemoteRatsAfterSync(companyEmpresaId!, remoteSession!.usuarioId);
      }
    } catch (e, st) { debugPrint("Error: $e$st");
      _isSubmitting = false;
      _errorMessage = 'Não foi possível salvar o RAT.';
      notifyListeners();
      return false;
    }

    _isSubmitting = false;
    _isSaved = true;
    ultimoAlteradorUserId = rat.ultimoAlteradorUserId;
    ultimaAlteracaoEm = rat.ultimaAlteracaoEm;
    notifyListeners();
    return true;
  }

  Future<void> submit() async {
    await save();
  }

  Future<bool> reopenForCorrection(String motivo) async {
    final trimmed = motivo.trim();
    if (!canReopenForCorrection) {
      _errorMessage = 'Este RAT não pode ser reaberto para correção.';
      notifyListeners();
      return false;
    }

    if (trimmed.length < 5) {
      _errorMessage = 'Informe um motivo com pelo menos 5 caracteres.';
      notifyListeners();
      return false;
    }

    final remoteSession = _remoteSession;
    if (remoteSession == null || !remoteSession.hasCompanyContext) {
      _errorMessage = 'Sessão remota não restaurada.';
      notifyListeners();
      return false;
    }

    final previousStatus = status;
    final previousUltimoAlteradorUserId = ultimoAlteradorUserId;
    final previousUltimaAlteracaoEm = ultimaAlteracaoEm;
    final previousReabertaParaCorrecaoEm = reabertaParaCorrecaoEm;
    final previousReabertaParaCorrecaoPorUserId = reabertaParaCorrecaoPorUserId;
    final previousMotivoReabertura = motivoReabertura;
    final previousAssinaturaInvalidadaEm = assinaturaInvalidadaEm;
    final previousAssinaturaInvalidadaPorUserId = assinaturaInvalidadaPorUserId;
    final now = DateTime.now();

    status = RatStatus.draft;
    ultimoAlteradorUserId = remoteSession.usuarioId;
    ultimaAlteracaoEm = now;
    reabertaParaCorrecaoEm = now;
    reabertaParaCorrecaoPorUserId = remoteSession.usuarioId;
    motivoReabertura = trimmed;
    assinaturaInvalidadaEm = now;
    assinaturaInvalidadaPorUserId = remoteSession.usuarioId;

    try {
      final saved = await save();
      if (!saved) {
        status = previousStatus;
        ultimoAlteradorUserId = previousUltimoAlteradorUserId;
        ultimaAlteracaoEm = previousUltimaAlteracaoEm;
        reabertaParaCorrecaoEm = previousReabertaParaCorrecaoEm;
        reabertaParaCorrecaoPorUserId = previousReabertaParaCorrecaoPorUserId;
        motivoReabertura = previousMotivoReabertura;
        assinaturaInvalidadaEm = previousAssinaturaInvalidadaEm;
        assinaturaInvalidadaPorUserId = previousAssinaturaInvalidadaPorUserId;
        notifyListeners();
        return false;
      }
    } catch (error) {
      // Rollback on exception to maintain consistent state
      status = previousStatus;
      ultimoAlteradorUserId = previousUltimoAlteradorUserId;
      ultimaAlteracaoEm = previousUltimaAlteracaoEm;
      reabertaParaCorrecaoEm = previousReabertaParaCorrecaoEm;
      reabertaParaCorrecaoPorUserId = previousReabertaParaCorrecaoPorUserId;
      motivoReabertura = previousMotivoReabertura;
      assinaturaInvalidadaEm = previousAssinaturaInvalidadaEm;
      assinaturaInvalidadaPorUserId = previousAssinaturaInvalidadaPorUserId;
      _errorMessage = 'Erro ao reabrir RAT para correção.';
      notifyListeners();
      return false;
    }

    _signaturePreviewBytes = null;
    notifyListeners();
    return true;
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
    final remoteSession = _remoteSession;
    final isCompanyMode = remoteSession?.hasCompanyContext ?? false;
    final companyEmpresaId = isCompanyMode ? remoteSession!.empresaId! : null;
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
        await _syncCoordinator?.syncAfterDelete(
          rat: deletedRat,
          empresaId: companyEmpresaId!,
          usuarioId: remoteSession!.usuarioId,
        );
        _downloadRemoteRatsAfterSync(companyEmpresaId!, remoteSession!.usuarioId);
      }
    } catch (e, st) { debugPrint("Error: $e$st");
      _isSubmitting = false;
      _errorMessage = 'Não foi possível excluir o RAT.';
      notifyListeners();
      return false;
    }

    _isSubmitting = false;
    _isSaved = true;
    notifyListeners();
    return true;
  }

  void _downloadRemoteRatsAfterSync(String empresaId, String usuarioId) {
    final downloadRemoteRats = _downloadRemoteRats;
    if (downloadRemoteRats == null) return;

    final papel =
        _remoteSession?.papelEmpresa?.name ??
        _remoteSession?.papelGlobal?.name ??
        'unknown';

    unawaited(() async {
      try {
        await downloadRemoteRats.call(
          empresaId: empresaId,
          usuarioId: usuarioId,
          papel: papel,
        );
      } catch (e, st) { debugPrint("Error: $e$st");
        // RAT local ja salvo; retry pela lista de RATs.
      }
    }());
  }

  Future<bool> saveSignature(Uint8List bytes) async {
    if (bytes.length > maxSignatureBytes) {
      _errorMessage = 'Assinatura muito grande. Use um canvas menor.';
      notifyListeners();
      return false;
    }

    final saved = await save(enqueueSync: false);
    if (!saved) {
      return false;
    }

    final currentSignatures = await _assinaturaRepository.listByRatId(ratId);
    for (final assinatura in currentSignatures) {
      // Enfileira delete remoto antes de remover localmente.
      // Se a assinatura já syncou, o Storage/tabela remota fica órfã
      // sem este step.
      final remoteSession = _remoteSession;
      if (remoteSession != null && remoteSession.hasCompanyContext) {
        // Fire-and-forget: local delete proceeds even if remote sync fails.
        unawaited(_enqueueAssinaturaSync?.delete(
          assinatura,
          empresaId: remoteSession.empresaId!,
          usuarioId: remoteSession.usuarioId,
          ratId: ratId,
        ));
      }

      if (assinatura.storageMode == StorageMode.localFile) {
        await _localSignatureAssetStore.delete(assinatura.assetRef);
      }
      await _assinaturaRepository.delete(assinatura.id);
    }

    final now = DateTime.now();
    // Using microsecondsSinceEpoch for signature IDs.
    // Rationale: Single-user app, microsecond precision is sufficient.
    // UUID would add dependency; risk of collision is negligible.
    final assinaturaId = 'assinatura-${now.microsecondsSinceEpoch}';

    await _assinaturaRepository.saveBytes(
      assinaturaId: assinaturaId,
      bytes: bytes,
      assetRef: 'signatures/$assinaturaId.png',
      ratId: ratId,
    );

    final assinatura = Assinatura(
      id: assinaturaId,
      ratId: ratId,
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
    notifyListeners();

    final remoteSession = _remoteSession;
    final isCompanyMode = remoteSession?.hasCompanyContext ?? false;

    if (isCompanyMode) {
      final empresaId = remoteSession!.empresaId!;
      final usuarioId = remoteSession.usuarioId;
      await _syncCoordinator?.syncAfterSignature(
        assinatura: assinatura,
        empresaId: empresaId,
        usuarioId: usuarioId,
        ratId: ratId,
      );
      _downloadRemoteRatsAfterSync(empresaId, usuarioId);
    }

    return true;
  }

  Future<String?> _resolveEmpresaNome() async {
    final empresaId = _remoteSession?.empresaId;
    if (empresaId == null || _supabaseClientFactory == null) return null;
    try {
      final client = await _supabaseClientFactory
          .tryCreateAuthenticatedClient();
      if (client == null) {
        return null;
      }
      final row = await client
          .from('empresas')
          .select('nome')
          .eq('id', empresaId)
          .maybeSingle();
      return row?['nome'] as String?;
    } catch (e, st) { debugPrint("Error: $e$st");
      return null;
    }
  }

  /// Retorna os dados necessários para a tela de preview do PDF.
  ///
  /// [persist] controla se a RAT é salva antes de gerar a prévia:
  /// - `true` (padrão, usado na edição): salva primeiro para não perder
  ///   alterações em andamento;
  /// - `false` (usado na lista): só abre a prévia da RAT já persistida, sem
  ///   salvar — útil inclusive para RAT de outro técnico (somente leitura).
  /// Nunca enfileira sync.
  Future<PdfPreviewData?> prepareForPdfPreview({bool persist = true}) async {
    empresaNome ??= await _resolveEmpresaNome();
    if (persist && canEditFields) {
      final saved = await save(enqueueSync: false);
      if (!saved) {
        return null;
      }
    } else if (_initialRat == null && !_isSaved) {
      _errorMessage = 'Salve o RAT antes de gerar a prévia.';
      notifyListeners();
      return null;
    }

    // Garante que a assinatura está carregada.
    if (_assinatura != null && _signaturePreviewBytes == null) {
      try {
        _signaturePreviewBytes = await _assinaturaRepository.readBytes(
          _assinatura!.id,
        );
      } catch (e, st) { debugPrint("Error: $e$st");
        _signaturePreviewBytes = null;
      }
    }

    final shareData = await _shareRatLocally(
      ratId: ratId,
      scope: _shareScope(),
    );

    if (!shareData.success || shareData.rat == null) {
      return null;
    }

    return PdfPreviewData(
      rat: shareData.rat!,
      signatureBytes: isSignaturePending ? null : _signaturePreviewBytes,
      assinaturaPendente: isSignaturePending,
      empresaNome: empresaNome,
      tecnicoNome: tecnicoNome,
    );
  }

  /// Compartilha o PDF da RAT atual.
  Future<bool> sharePdf() async {
    if (canEditFields) {
      final saved = await save(enqueueSync: false);
      if (!saved) {
        return false;
      }
    } else if (_initialRat == null && !_isSaved) {
      _errorMessage = 'Salve o RAT antes de compartilhar o PDF.';
      notifyListeners();
      return false;
    }

    _isSharing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final shareData = await _shareRatLocally(
        ratId: ratId,
        scope: _shareScope(),
      );
      if (!shareData.success) {
        _errorMessage = shareData.errorMessage;
        return false;
      }

      await _ratPdfShareService.share(
        shareData,
        empresaNome: empresaNome,
        tecnicoNome: tecnicoNome,
        assinaturaPendente: isSignaturePending,
      );
      return true;
    } catch (e, st) { debugPrint("Error: $e$st");
      _errorMessage = 'Não foi possível compartilhar o PDF.';
      return false;
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }

  /// Salva o PDF no dispositivo (seletor de arquivo), sem abrir share sheet.
  Future<bool> savePdf() async {
    if (canEditFields) {
      final saved = await save(enqueueSync: false);
      if (!saved) {
        return false;
      }
    } else if (_initialRat == null && !_isSaved) {
      _errorMessage = 'Salve o RAT antes de salvar o PDF.';
      notifyListeners();
      return false;
    }

    _isSharing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final shareData = await _shareRatLocally(
        ratId: ratId,
        scope: _shareScope(),
      );
      if (!shareData.success) {
        _errorMessage = shareData.errorMessage;
        return false;
      }

      final exported = await _ratPdfShareService.exportToDevice(
        shareData,
        empresaNome: empresaNome,
        tecnicoNome: tecnicoNome,
        assinaturaPendente: isSignaturePending,
      );
      if (!exported) {
        return false;
      }
      return true;
    } catch (e, st) { debugPrint("Error: $e\n$st");
      _errorMessage = 'Não foi possível salvar o PDF.';
      return false;
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }

  RatListScope _shareScope() {
    final remoteSession = _remoteSession;
    if (remoteSession == null || !remoteSession.hasCompanyContext) {
      return const RatListScope.local();
    }

    final empresaId = remoteSession.empresaId!;
    if (remoteSession.isGerente || remoteSession.isAdminEmpresa) {
      return RatListScope.companyManager(empresaId: empresaId);
    }

    final tecnicoId = remoteSession.tecnicoId;
    if (tecnicoId == null) {
      return RatListScope.companyManager(empresaId: empresaId);
    }

    return RatListScope.companyTechnician(
      empresaId: empresaId,
      tecnicoId: tecnicoId,
    );
  }

  Rat _ratWithCurrentAudit(Rat rat) {
    return rat.copyWith(
      status: status,
      ultimoAlteradorUserId: ultimoAlteradorUserId,
      ultimaAlteracaoEm: ultimaAlteracaoEm,
      reabertaParaCorrecaoEm: reabertaParaCorrecaoEm,
      reabertaParaCorrecaoPorUserId: reabertaParaCorrecaoPorUserId,
      motivoReabertura: motivoReabertura,
      assinaturaInvalidadaEm: assinaturaInvalidadaEm,
      assinaturaInvalidadaPorUserId: assinaturaInvalidadaPorUserId,
    );
  }
}

String _newRatId() {
  return const Uuid().v4();
}

String _newRatNumber() {
  // Use timestamp + short UUID to ensure uniqueness while keeping readable format
  final uuid = const Uuid().v4().substring(0, 8);
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
  return '$timestamp-$uuid';
}

String? _optionalText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _normalizeHour(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 4) {
    return null;
  }

  final hour = int.tryParse(digits.substring(0, 2));
  final minute = int.tryParse(digits.substring(2, 4));

  if (hour == null || minute == null) {
    return null;
  }

  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

bool _isHourInRange(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 4) {
    return false;
  }

  final hour = int.tryParse(digits.substring(0, 2));
  final minute = int.tryParse(digits.substring(2, 4));

  if (hour == null || minute == null) {
    return false;
  }

  return hour <= 23 && minute <= 59;
}

bool _isEndAfterStart(String start, String end) {
  return _minutesSinceMidnight(end) > _minutesSinceMidnight(start);
}

int _minutesSinceMidnight(String value) {
  final parts = value.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);

  return hour * 60 + minute;
}

class PdfPreviewData {
  const PdfPreviewData({
    required this.rat,
    this.signatureBytes,
    this.assinaturaPendente = false,
    this.empresaNome,
    this.tecnicoNome,
  });

  final Rat rat;
  final Uint8List? signatureBytes;
  final bool assinaturaPendente;
  final String? empresaNome;
  final String? tecnicoNome;
}
