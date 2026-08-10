import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/permissions/rat_permissions.dart';
import 'package:techreport/features/rat/domain/services/rat_sync_coordinator.dart';
import 'package:techreport/features/sync/data/usecases/enqueue_assinatura_sync.dart';
import 'package:techreport/features/sync/domain/usecases/download_remote_rats.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_form_state.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_signature_manager.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_pdf_generator.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_sync_handler.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:uuid/uuid.dart';

/// ViewModel for the RAT form screen.
///
/// Facade that orchestrates specialized classes:
/// - [RatFormState]: form fields and validation
/// - [RatSignatureManager]: signature lifecycle
/// - [RatPdfGenerator]: PDF preparation
/// - [RatSyncHandler]: sync coordination
///
/// Public API unchanged from original monolithic implementation.
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
    String? ownerDisplayName,
  }) : _ratRepository = ratRepository,
       _ratPdfShareService = ratPdfShareService,
       _shareRatLocally = shareRatLocally,
       _initialRat = initialRat,
       _ownerDisplayName = ownerDisplayName,
       ratId = initialRat?.id ?? _newRatId(),
       numero = initialRat?.numero ?? _newRatNumber(),
       _remoteSession = remoteSession,
       _isSaved = initialRat != null,
       _ultimoAlteradorUserId = initialRat?.ultimoAlteradorUserId,
       _ultimaAlteracaoEm = initialRat?.ultimaAlteracaoEm,
       _reabertaParaCorrecaoEm = initialRat?.reabertaParaCorrecaoEm,
       _reabertaParaCorrecaoPorUserId =
           initialRat?.reabertaParaCorrecaoPorUserId,
       _motivoReabertura = initialRat?.motivoReabertura,
       _assinaturaInvalidadaEm = initialRat?.assinaturaInvalidadaEm,
       _assinaturaInvalidadaPorUserId =
           initialRat?.assinaturaInvalidadaPorUserId,
       _formState = RatFormState(initialRat: initialRat),
       _syncHandler = RatSyncHandler(
         syncCoordinator: syncCoordinator,
         downloadRemoteRats: downloadRemoteRats,
         empresaId: remoteSession?.empresaId,
         usuarioId: remoteSession?.usuarioId,
         papel:
             remoteSession?.papelEmpresa?.name ??
             remoteSession?.papelGlobal?.name,
       ) {
    _signatureManager = RatSignatureManager(
      assinaturaRepository: assinaturaRepository,
      localSignatureAssetStore: localSignatureAssetStore,
      ratId: ratId,
      onError: (msg) {
        _errorMessage = msg;
      },
      enqueueAssinaturaSync: enqueueAssinaturaSync,
    );
    _pdfGenerator = RatPdfGenerator(
      ratPdfShareService: ratPdfShareService,
      shareRatLocally: shareRatLocally,
      ratId: ratId,
      supabaseClientFactory: supabaseClientFactory,
    );
    _formState.addListener(_onFormStateChanged);
    // Forward signature manager notifications
    _signatureManager.addListener(_onSignatureManagerChanged);
  }

  static const _permissions = RatPermissions();

  /// 1 MB maximum signature size.
  static const maxSignatureBytes = 1 * 1024 * 1024;

  final RatRepository _ratRepository;
  final RatPdfShareService _ratPdfShareService;
  final ShareRatLocally _shareRatLocally;
  final Rat? _initialRat;
  SessaoRemota? _remoteSession;
  final String? _ownerDisplayName;
  final String ratId;
  final String numero;

  // Specialized classes
  final RatFormState _formState;
  late final RatSignatureManager _signatureManager;
  late final RatPdfGenerator _pdfGenerator;
  late final RatSyncHandler _syncHandler;

  bool _isSubmitting = false;
  bool _isSharing = false;
  bool _isSaved;
  String? _errorMessage;
  String? _feedbackMessage;
  bool _permissionChanged = false;

  // Audit fields (managed directly for simplicity)
  String? _ultimoAlteradorUserId;
  DateTime? _ultimaAlteracaoEm;
  DateTime? _reabertaParaCorrecaoEm;
  String? _reabertaParaCorrecaoPorUserId;
  String? _motivoReabertura;
  DateTime? _assinaturaInvalidadaEm;
  String? _assinaturaInvalidadaPorUserId;

  void _onFormStateChanged() {
    notifyListeners();
  }

  void _onSignatureManagerChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _formState.removeListener(_onFormStateChanged);
    _signatureManager.removeListener(_onSignatureManagerChanged);
    _formState.dispose();
    super.dispose();
  }

  // Forwarded form state getters
  String get clienteNome => _formState.clienteNome;
  String get responsavelRecebimento => _formState.responsavelRecebimento;
  String get responsavelDocumento => _formState.responsavelDocumento;
  DateTime? get dataVisita => _formState.dataVisita;
  String get horarioInicioAtendimento => _formState.horarioInicioAtendimento;
  String get horarioTerminoAtendimento => _formState.horarioTerminoAtendimento;
  String get descricao => _formState.descricao;
  EquipamentoMovimentoTipo get equipamentoMovimentoTipo =>
      _formState.equipamentoMovimentoTipo;
  String get equipamentoDescricao => _formState.equipamentoDescricao;
  String get equipamentoObservacao => _formState.equipamentoObservacao;
  RatStatus get status => _formState.status;

  bool get isSubmitting => _isSubmitting;
  bool get isSharing => _isSharing;
  bool get isSaved => _isSaved;
  bool get hasSignature => _signatureManager.hasSignature;
  bool get hasValidSignature =>
      _signatureManager.hasSignature && !isSignaturePending;
  bool get isLoadingSignature => _signatureManager.isLoadingSignature;
  bool get isSavingSignature => _signatureManager.isSavingSignature;
  String? get errorMessage => _errorMessage;
  String? get feedbackMessage => _feedbackMessage;
  bool get isEditing => _initialRat != null;
  bool get shouldReloadOnClose => _isSaved;
  Uint8List? get signaturePreviewBytes =>
      _signatureManager.signaturePreviewBytes;

  bool get isSignaturePending {
    final invalidatedAt = _assinaturaInvalidadaEm;
    if (invalidatedAt == null) {
      return false;
    }

    final assinatura = _signatureManager.assinatura;
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

  /// True quando o formulario deve ser exibido em modo somente leitura.
  ///
  /// Tecnico nao-dono (que nao e gerente/admin) abre RAT de outro em modo
  /// somente leitura — campos desabilitados, sem botao salvar.
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

  bool get canViewAudit {
    final initialRat = _initialRat;
    return initialRat != null &&
        _remoteSession != null &&
        _permissions.canViewAudit(initialRat, _remoteSession);
  }

  String get ownerDisplayName {
    final configured = _ownerDisplayName?.trim();
    if (configured != null && configured.isNotEmpty) return configured;
    final tecnicoId = _initialRat?.tecnicoId;
    if (tecnicoId == null || tecnicoId.isEmpty) {
      return 'Proprietário não identificado';
    }
    return 'Técnico · ${tecnicoId.length <= 8 ? tecnicoId : tecnicoId.substring(0, 8)}';
  }

  bool get isCorrectingOtherOwner {
    final rat = _initialRat;
    final current = _remoteSession;
    return rat != null &&
        current != null &&
        _permissions.isManagerOrAdmin(rat, current) &&
        !_permissions.isOwner(rat, current);
  }

  bool get permissionChanged => _permissionChanged;

  bool get canEdit {
    final initialRat = _initialRat;
    if (initialRat == null) return _canCreateWithCurrentSession;
    return _permissions.canEdit(initialRat, _remoteSession);
  }

  bool get _canCreateWithCurrentSession {
    final current = _remoteSession;
    if (current == null) return true;
    return current.hasCompanyContext &&
        !current.isAppAdmin &&
        (current.isTecnico || current.isGerente || current.isAdminEmpresa);
  }

  void updateRemoteSession(SessaoRemota? session) {
    final previouslyAllowed = canEdit;
    _remoteSession = session;
    if (previouslyAllowed && !canEdit) {
      _permissionChanged = true;
      _errorMessage =
          'Sua permissão para editar esta RAT mudou. Copie o que precisar e volte para a lista.';
    }
    notifyListeners();
  }

  bool get canReopenForCorrection {
    final initialRat = _initialRat;
    if (initialRat == null || !hasValidSignature) {
      return false;
    }

    return _permissions.canReopenForCorrection(
      _ratWithCurrentAudit(initialRat),
      _remoteSession,
    );
  }

  void setClienteNome(String value) => _formState.setClienteNome(value);
  void setResponsavelRecebimento(String value) =>
      _formState.setResponsavelRecebimento(value);
  void setResponsavelDocumento(String value) =>
      _formState.setResponsavelDocumento(value);
  void setDataVisita(DateTime? value) => _formState.setDataVisita(value);
  void setHorarioInicioAtendimento(String value) =>
      _formState.setHorarioInicioAtendimento(value);
  void setHorarioTerminoAtendimento(String value) =>
      _formState.setHorarioTerminoAtendimento(value);
  void setDescricao(String value) => _formState.setDescricao(value);
  void setEquipamentoMovimentoTipo(EquipamentoMovimentoTipo value) =>
      _formState.setEquipamentoMovimentoTipo(value);
  void setEquipamentoDescricao(String value) =>
      _formState.setEquipamentoDescricao(value);
  void setEquipamentoObservacao(String value) =>
      _formState.setEquipamentoObservacao(value);
  void setStatus(RatStatus value) => _formState.setStatus(value);

  String? empresaNome;

  String? get tecnicoNome => _remoteSession?.nome;

  String? validate() => _formState.validate();

  Future<void> loadSignatureStatus() => _signatureManager.loadSignatureStatus();

  /// Constrói o objeto Rat a partir dos campos do formulário.
  Rat _buildRatForSave({
    required bool isCompanyMode,
    required SessaoRemota? remoteSession,
    required DateTime now,
  }) {
    final auditUserId = isCompanyMode
        ? _remoteSession!.usuarioId
        : _ultimoAlteradorUserId;
    final auditUpdatedAt = isCompanyMode ? now : _ultimaAlteracaoEm;

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
      clienteNome: _formState.clienteNome.trim(),
      responsavelRecebimento: _formState.responsavelRecebimento.trim(),
      responsavelDocumento: _optionalText(_formState.responsavelDocumento),
      dataVisita: _formState.dataVisita,
      horarioInicioAtendimento: _normalizeHour(
        _formState.horarioInicioAtendimento,
      )!,
      horarioTerminoAtendimento: _normalizeHour(
        _formState.horarioTerminoAtendimento,
      )!,
      descricao: _formState.descricao.trim(),
      equipamentoMovimentoTipo: _formState.equipamentoMovimentoTipo,
      equipamentoDescricao: _formState.equipamentoDescricao.trim().isEmpty
          ? null
          : _formState.equipamentoDescricao.trim(),
      equipamentoObservacao: _formState.equipamentoObservacao.trim().isEmpty
          ? null
          : _formState.equipamentoObservacao.trim(),
      status: _formState.status,
      syncStatus: isCompanyMode
          ? RatSyncStatus.pendingSync
          : RatSyncStatus.localOnly,
      createdAt: _initialRat?.createdAt ?? now,
      updatedAt: now,
      deletedAt: _initialRat?.deletedAt,
      ultimoAlteradorUserId: auditUserId,
      ultimaAlteracaoEm: auditUpdatedAt,
      reabertaParaCorrecaoEm: _reabertaParaCorrecaoEm,
      reabertaParaCorrecaoPorUserId: _reabertaParaCorrecaoPorUserId,
      motivoReabertura: _motivoReabertura,
      assinaturaInvalidadaEm: _assinaturaInvalidadaEm,
      assinaturaInvalidadaPorUserId: _assinaturaInvalidadaPorUserId,
    );
  }

  Future<bool> save({bool enqueueSync = true}) async {
    return _saveCurrentRat(enqueueSync: enqueueSync, requireEditable: true);
  }

  Future<bool> _saveCurrentRat({
    required bool enqueueSync,
    required bool requireEditable,
  }) async {
    if (requireEditable && !canEditFields) {
      _errorMessage = _permissionChanged
          ? 'Sua permissão para editar esta RAT mudou. Copie o que precisar e volte para a lista.'
          : isLockedUntilReopen
          ? 'Reabra este RAT para correcao antes de editar.'
          : 'Este RAT pertence a outro tecnico.';
      notifyListeners();
      return false;
    }

    final validationError = validate();
    final remoteSession = _remoteSession;
    final isCompanyMode = remoteSession?.hasCompanyContext ?? false;

    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _feedbackMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final rat = _buildRatForSave(
      isCompanyMode: isCompanyMode,
      remoteSession: remoteSession,
      now: now,
    );

    try {
      await _ratRepository.save(rat);
    } catch (e, st) {
      debugPrint("Error: $e$st");
      _isSubmitting = false;
      _errorMessage = 'Nao foi possivel salvar o RAT.';
      notifyListeners();
      return false;
    }

    var syncQueued = false;
    if (enqueueSync && isCompanyMode) {
      try {
        await _syncHandler.syncAfterSave(rat);
      } catch (error, stackTrace) {
        debugPrint('Sync pendente após salvar RAT: $error\n$stackTrace');
        syncQueued = true;
      }
    }

    _isSubmitting = false;
    _isSaved = true;
    _ultimoAlteradorUserId = rat.ultimoAlteradorUserId;
    _ultimaAlteracaoEm = rat.ultimaAlteracaoEm;
    _formState.markClean();
    if (isCorrectingOtherOwner) {
      _feedbackMessage = syncQueued
          ? 'Alterações salvas neste dispositivo. O histórico será atualizado após a sincronização.'
          : 'Alterações salvas e registradas no histórico.';
    }
    notifyListeners();
    return true;
  }

  Future<void> submit() async {
    await save();
  }

  Future<bool> reopenForCorrection(String motivo) async {
    final trimmed = motivo.trim();
    if (!canReopenForCorrection) {
      _errorMessage = 'Este RAT nao pode ser reaberto para correcao.';
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
      _errorMessage = 'Sessao remota nao restaurada.';
      notifyListeners();
      return false;
    }

    // Save current state for rollback
    final previousStatus = _formState.status;
    final previousUltimoAlteradorUserId = _ultimoAlteradorUserId;
    final previousUltimaAlteracaoEm = _ultimaAlteracaoEm;
    final previousReabertaParaCorrecaoEm = _reabertaParaCorrecaoEm;
    final previousReabertaParaCorrecaoPorUserId =
        _reabertaParaCorrecaoPorUserId;
    final previousMotivoReabertura = _motivoReabertura;
    final previousAssinaturaInvalidadaEm = _assinaturaInvalidadaEm;
    final previousAssinaturaInvalidadaPorUserId =
        _assinaturaInvalidadaPorUserId;
    final now = DateTime.now();

    // Apply new state
    _formState.status = RatStatus.draft;
    _ultimoAlteradorUserId = remoteSession.usuarioId;
    _ultimaAlteracaoEm = now;
    _reabertaParaCorrecaoEm = now;
    _reabertaParaCorrecaoPorUserId = remoteSession.usuarioId;
    _motivoReabertura = trimmed;
    _assinaturaInvalidadaEm = now;
    _assinaturaInvalidadaPorUserId = remoteSession.usuarioId;

    try {
      final saved = await save();
      if (!saved) {
        _rollbackReopenState(
          previousStatus: previousStatus,
          previousUltimoAlteradorUserId: previousUltimoAlteradorUserId,
          previousUltimaAlteracaoEm: previousUltimaAlteracaoEm,
          previousReabertaParaCorrecaoEm: previousReabertaParaCorrecaoEm,
          previousReabertaParaCorrecaoPorUserId:
              previousReabertaParaCorrecaoPorUserId,
          previousMotivoReabertura: previousMotivoReabertura,
          previousAssinaturaInvalidadaEm: previousAssinaturaInvalidadaEm,
          previousAssinaturaInvalidadaPorUserId:
              previousAssinaturaInvalidadaPorUserId,
        );
        return false;
      }
    } catch (error) {
      _rollbackReopenState(
        previousStatus: previousStatus,
        previousUltimoAlteradorUserId: previousUltimoAlteradorUserId,
        previousUltimaAlteracaoEm: previousUltimaAlteracaoEm,
        previousReabertaParaCorrecaoEm: previousReabertaParaCorrecaoEm,
        previousReabertaParaCorrecaoPorUserId:
            previousReabertaParaCorrecaoPorUserId,
        previousMotivoReabertura: previousMotivoReabertura,
        previousAssinaturaInvalidadaEm: previousAssinaturaInvalidadaEm,
        previousAssinaturaInvalidadaPorUserId:
            previousAssinaturaInvalidadaPorUserId,
      );
      _errorMessage = 'Erro ao reabrir RAT para correcao.';
      notifyListeners();
      return false;
    }

    _signatureManager.clearPreview();
    notifyListeners();
    return true;
  }

  void _rollbackReopenState({
    required RatStatus previousStatus,
    required String? previousUltimoAlteradorUserId,
    required DateTime? previousUltimaAlteracaoEm,
    required DateTime? previousReabertaParaCorrecaoEm,
    required String? previousReabertaParaCorrecaoPorUserId,
    required String? previousMotivoReabertura,
    required DateTime? previousAssinaturaInvalidadaEm,
    required String? previousAssinaturaInvalidadaPorUserId,
  }) {
    _formState.status = previousStatus;
    _ultimoAlteradorUserId = previousUltimoAlteradorUserId;
    _ultimaAlteracaoEm = previousUltimaAlteracaoEm;
    _reabertaParaCorrecaoEm = previousReabertaParaCorrecaoEm;
    _reabertaParaCorrecaoPorUserId = previousReabertaParaCorrecaoPorUserId;
    _motivoReabertura = previousMotivoReabertura;
    _assinaturaInvalidadaEm = previousAssinaturaInvalidadaEm;
    _assinaturaInvalidadaPorUserId = previousAssinaturaInvalidadaPorUserId;
    notifyListeners();
  }

  Future<bool> deleteRat() async {
    final initialRat = _initialRat;
    if (initialRat == null || !canDelete) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _feedbackMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final remoteSession = _remoteSession;
    final isCompanyMode = remoteSession?.hasCompanyContext ?? false;
    final deletedRat = initialRat.copyWith(
      syncStatus: isCompanyMode
          ? RatSyncStatus.pendingSync
          : RatSyncStatus.localOnly,
      updatedAt: now,
      deletedAt: now,
    );

    try {
      await _ratRepository.save(deletedRat);
    } catch (e, st) {
      debugPrint("Error: $e$st");
      _isSubmitting = false;
      _errorMessage = 'Nao foi possivel excluir o RAT.';
      notifyListeners();
      return false;
    }

    var syncQueued = false;
    if (isCompanyMode) {
      try {
        await _syncHandler.syncAfterDelete(deletedRat);
      } catch (error, stackTrace) {
        debugPrint('Sync pendente após mover RAT: $error\n$stackTrace');
        syncQueued = true;
      }
    }

    _isSubmitting = false;
    _isSaved = true;
    _feedbackMessage = syncQueued
        ? 'RAT movida para a lixeira neste dispositivo. A sincronização será feita quando houver conexão.'
        : 'RAT movida para a lixeira.';
    notifyListeners();
    return true;
  }

  Future<bool> saveSignature(Uint8List bytes) async {
    final lockedWithOperationalChanges =
        isLockedUntilReopen && _formState.isDirty;
    if (!canEdit || lockedWithOperationalChanges) {
      _errorMessage = _permissionChanged
          ? 'Sua permissão para editar esta RAT mudou. Copie o que precisar e volte para a lista.'
          : lockedWithOperationalChanges
          ? 'Reabra esta RAT antes de alterar dados e substituir a assinatura.'
          : 'Você não tem permissão para alterar esta RAT.';
      notifyListeners();
      return false;
    }
    final remoteSession = _remoteSession;
    final isCompanyMode = remoteSession?.hasCompanyContext ?? false;
    final previousStatus = _formState.status;
    final shouldFinalize = previousStatus == RatStatus.draft;

    if (shouldFinalize) {
      _formState.setStatus(RatStatus.finalizado);
    }

    final result = await _signatureManager.saveSignature(
      bytes,
      empresaId: remoteSession?.empresaId ?? '',
      usuarioId: remoteSession?.usuarioId ?? '',
      hasCompanyContext: isCompanyMode,
      saveRat: ({required bool enqueueSync}) =>
          _saveCurrentRat(enqueueSync: enqueueSync, requireEditable: false),
      syncAfterSignature: (empresaId, usuarioId) async {
        final assinatura = _signatureManager.assinatura;
        if (assinatura != null) {
          await _syncHandler.syncAfterSignature(assinatura);
        }
      },
      downloadRemoteRatsAfterSync: (empresaId, usuarioId) async {
        // Triggered by syncAfterSignature in sync handler
      },
    );

    if (!result && shouldFinalize) {
      _formState.setStatus(previousStatus);
    }

    return result;
  }

  Future<String?> _resolveEmpresaNome() async {
    return _pdfGenerator.resolveEmpresaNome(_remoteSession?.empresaId);
  }

  /// Retorna os dados necessarios para a tela de preview do PDF.
  ///
  /// [persist] controla se a RAT e salva antes de gerar a previa:
  /// - `true` (padrao, usado na edicao): salva primeiro para nao perder
  ///   alteracoes em andamento;
  /// - `false` (usado na lista): só abre a previa da RAT ja persistida, sem
  ///   salvar — util inclusive para RAT de outro tecnico (somente leitura).
  /// Nunca enfileira sync.
  Future<PdfPreviewData?> prepareForPdfPreview({bool persist = true}) async {
    empresaNome ??= await _resolveEmpresaNome();
    if (persist && canEditFields) {
      final saved = await save(enqueueSync: false);
      if (!saved) {
        return null;
      }
    } else if (_initialRat == null && !_isSaved) {
      _errorMessage = 'Salve o RAT antes de gerar a previa.';
      notifyListeners();
      return null;
    }

    // Ensure signature is loaded
    await loadSignatureStatus();

    final rat = _initialRat ?? await _ratRepository.getById(ratId);
    if (rat == null) {
      return null;
    }

    return _pdfGenerator.prepareForPreview(
      rat: rat,
      signatureBytes: isSignaturePending ? null : signaturePreviewBytes,
      assinaturaPendente: isSignaturePending,
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
    } catch (e, st) {
      debugPrint("Error: $e$st");
      _errorMessage = 'Nao foi possivel compartilhar o PDF.';
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
    } catch (e, st) {
      debugPrint("Error: $e\n$st");
      _errorMessage = 'Nao foi possivel salvar o PDF.';
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
      status: _formState.status,
      ultimoAlteradorUserId: _ultimoAlteradorUserId,
      ultimaAlteracaoEm: _ultimaAlteracaoEm,
      reabertaParaCorrecaoEm: _reabertaParaCorrecaoEm,
      reabertaParaCorrecaoPorUserId: _reabertaParaCorrecaoPorUserId,
      motivoReabertura: _motivoReabertura,
      assinaturaInvalidadaEm: _assinaturaInvalidadaEm,
      assinaturaInvalidadaPorUserId: _assinaturaInvalidadaPorUserId,
    );
  }
}

String _newRatId() {
  return const Uuid().v4();
}

String _newRatNumber() {
  final uuid = const Uuid().v4().substring(0, 8);
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(
    5,
  );
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
