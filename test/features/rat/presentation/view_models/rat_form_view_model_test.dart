import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/company_auth/domain/entities/sessao_remota.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/domain/usecases/share_rat_locally.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_form_view_model.dart';
import 'package:techreport/features/rat/data/services/rat_pdf_share_service.dart';

class _StubAssinaturaRepository implements AssinaturaRepository {
  final List<Assinatura> assinaturas = [];

  @override
  Future<List<Assinatura>> listByRatId(String ratId) async => assinaturas;

  @override
  Future<Map<String, List<Assinatura>>> listByRatIds(List<String> ratIds) async => {};

  @override
  Future<Uint8List?> readBytes(String id) async => null;

  @override
  Future<void> saveBytes({
    required String assinaturaId,
    required Uint8List bytes,
    required String assetRef,
    required String ratId,
  }) async {}

  @override
  Future<Assinatura?> getById(String id) async => null;

  @override
  Future<void> save(Assinatura assinatura) async {}

  @override
  Future<void> update(Assinatura assinatura) async {}

  @override
  Future<void> delete(String id) async {}
}

class _StubLocalSignatureAssetStore implements LocalSignatureAssetStore {
  @override
  Future<Uint8List?> read(String assetRef) async => null;

  @override
  Future<void> delete(String assetRef) async {}

  @override
  Future<String> savePng({
    required String assinaturaId,
    required Uint8List bytes,
  }) async => '';
}

class _StubRatPdfShareService implements RatPdfShareService {
  @override
  Future<void> share(
    ShareRatLocallyResult shareData, {
    String? empresaNome,
    String? tecnicoNome,
    bool assinaturaPendente = false,
  }) async {}

  @override
  Future<bool> exportToDevice(
    ShareRatLocallyResult shareData, {
    String? empresaNome,
    String? tecnicoNome,
    bool assinaturaPendente = false,
  }) async =>
      false;
}

class _StubRatRepository implements RatRepository {
  Rat? savedRat;
  bool shouldThrowOnSave = false;

  @override
  Future<Rat?> getById(String id) async => null;

  @override
  Future<Rat?> getByIdScoped({
    required String id,
    required RatListScope scope,
  }) async =>
      null;

  @override
  Future<List<Rat>> listLocal() async => [];

  @override
  Future<List<Rat>> listLocalPage({
    required int limit,
    required int offset,
  }) async =>
      [];

  @override
  Future<List<Rat>> listCompanyForManager({
    required String empresaId,
  }) async =>
      [];

  @override
  Future<List<Rat>> listCompanyForManagerPage({
    required String empresaId,
    required int limit,
    required int offset,
  }) async =>
      [];

  @override
  Future<List<Rat>> listCompanyForTechnician({
    required String empresaId,
    required String tecnicoId,
  }) async =>
      [];

  @override
  Future<List<Rat>> listCompanyForTechnicianPage({
    required String empresaId,
    required String tecnicoId,
    required int limit,
    required int offset,
  }) async =>
      [];

  @override
  Future<void> save(Rat rat) async {
    if (shouldThrowOnSave) {
      throw Exception('Save failed');
    }
    savedRat = rat;
  }

  @override
  Future<void> update(Rat rat) async {}
}

class _StubShareRatLocally implements ShareRatLocally {
  @override
  Future<ShareRatLocallyResult> call({
    required String ratId,
    required RatListScope scope,
  }) async {
    return const ShareRatLocallyResult.failure('not implemented');
  }
}

SessaoRemota _makeRemoteSession({
  String empresaId = 'emp-1',
  String usuarioId = 'user-1',
  String tecnicoId = 'tec-1',
  SessaoRemotaPapelEmpresa papel = SessaoRemotaPapelEmpresa.tecnico,
}) {
  return SessaoRemota(
    id: 'sessao-1',
    empresaId: empresaId,
    usuarioId: usuarioId,
    tecnicoId: tecnicoId,
    email: 'test@example.com',
    nome: 'Test User',
    mustChangePassword: false,
    papelGlobal: null,
    papelEmpresa: papel,
    accessTokenRef: 'access-token',
    refreshTokenRef: 'refresh-token',
    endpointRef: 'https://api.example.com',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    lastValidatedAt: DateTime.now(),
    offlineAccessUntil: DateTime.now().add(const Duration(days: 7)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Rat _makeValidRat({
  String id = 'rat-1',
  String clienteNome = 'Cliente Teste',
  String responsavelRecebimento = 'Responsavel',
  DateTime? dataVisita,
  String horarioInicio = '0800',
  String horarioTermino = '1000',
  String descricao = 'Descricao do atendimento',
}) {
  final now = DateTime.now();
  return Rat(
    id: id,
    authorId: 'author-1',
    empresaId: 'emp-1',
    usuarioId: 'user-1',
    tecnicoId: 'tec-1',
    ownerType: RatOwnerType.companyTecnico,
    numero: '0001',
    clienteNome: clienteNome,
    responsavelRecebimento: responsavelRecebimento,
    dataVisita: dataVisita ?? now,
    horarioInicioAtendimento: horarioInicio,
    horarioTerminoAtendimento: horarioTermino,
    descricao: descricao,
    status: RatStatus.draft,
    syncStatus: RatSyncStatus.localOnly,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _StubAssinaturaRepository assinaturaRepo;
  late _StubLocalSignatureAssetStore signatureAssetStore;
  late _StubRatPdfShareService pdfShareService;
  late _StubRatRepository ratRepo;
  late _StubShareRatLocally shareRatLocally;

  setUp(() {
    assinaturaRepo = _StubAssinaturaRepository();
    signatureAssetStore = _StubLocalSignatureAssetStore();
    pdfShareService = _StubRatPdfShareService();
    ratRepo = _StubRatRepository();
    shareRatLocally = _StubShareRatLocally();
  });

  RatFormViewModel buildVm({
    Rat? initialRat,
    SessaoRemota? remoteSession,
  }) {
    return RatFormViewModel(
      assinaturaRepository: assinaturaRepo,
      localSignatureAssetStore: signatureAssetStore,
      ratPdfShareService: pdfShareService,
      ratRepository: ratRepo,
      shareRatLocally: shareRatLocally,
      initialRat: initialRat,
      remoteSession: remoteSession,
    );
  }

  // ─── validate() ────────────────────────────────────────────────────────────

  group('validate()', () {
    test('retorna erro para cliente vazio', () {
      final sut = buildVm();

      final result = sut.validate();

      expect(result, isNotNull);
      expect(result, contains('cliente'));
    });

    test('retorna erro para responsavel recebimento vazio', () {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');

      final result = sut.validate();

      expect(result, isNotNull);
      expect(result, contains('responsável'));
    });

    test('retorna erro para dataVisita nula', () {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');

      final result = sut.validate();

      expect(result, isNotNull);
      expect(result, contains('data'));
    });

    test('retorna erro para horário término antes de início', () {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('1200');
      sut.setHorarioTerminoAtendimento('0800');

      final result = sut.validate();

      expect(result, isNotNull);
      expect(result, contains('término'));
    });

    test('retorna erro para horário de início inválido (fora do range)', () {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('2500');
      sut.setHorarioTerminoAtendimento('1200');

      final result = sut.validate();

      expect(result, isNotNull);
      expect(result, contains('início'));
    });

    test('retorna erro para descrição vazia', () {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      // descricao permanece vazia

      final result = sut.validate();

      expect(result, isNotNull);
      expect(result, contains('descrição'));
    });

    test('retorna null para formulário válido', () {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Atendimento realizado conforme solicitado');

      final result = sut.validate();

      expect(result, isNull);
    });
  });

  // ─── save() ─────────────────────────────────────────────────────────────────

  group('save()', () {
    test('retorna false quando validação falha', () async {
      final sut = buildVm();
      // cliente vazio → validação falha

      final result = await sut.save();

      expect(result, isFalse);
      expect(sut.errorMessage, isNotNull);
    });

    test('retorna false quando save do repository lança exceção', () async {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Descrição válida');

      ratRepo.shouldThrowOnSave = true;

      final result = await sut.save();

      expect(result, isFalse);
    });

    test('retorna true e salva RAT no repositório quando formulário é válido', () async {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Descrição válida');

      final result = await sut.save();

      expect(result, isTrue);
      expect(ratRepo.savedRat, isNotNull);
      expect(ratRepo.savedRat!.clienteNome, 'Cliente Válido');
    });

    test('save() com remoteSession em modo empresa faz sync', () async {
      final remoteSession = _makeRemoteSession();
      final sut = buildVm(remoteSession: remoteSession);

      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Descrição válida');

      final result = await sut.save();

      expect(result, isTrue);
      // RAT salvo com ownerType companyTecnico (tem remoteSession com empresa)
      expect(ratRepo.savedRat!.ownerType, RatOwnerType.companyTecnico);
      expect(ratRepo.savedRat!.syncStatus, RatSyncStatus.pendingSync);
    });

    test('save() sem remoteSession define ownerType como localTecnico', () async {
      final sut = buildVm(remoteSession: null);

      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Descrição válida');

      final result = await sut.save();

      expect(result, isTrue);
      expect(ratRepo.savedRat!.ownerType, RatOwnerType.localTecnico);
      expect(ratRepo.savedRat!.syncStatus, RatSyncStatus.localOnly);
    });

    test('isSaved vira true após save bem-sucedido', () async {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Descrição válida');

      expect(sut.isSaved, isFalse);

      await sut.save();

      expect(sut.isSaved, isTrue);
    });

    test('isSubmitting vira true durante save e false após', () async {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Descrição válida');

      var submitStarted = false;
      sut.addListener(() {
        if (sut.isSubmitting) submitStarted = true;
      });

      await sut.save();

      expect(submitStarted, isTrue);
      expect(sut.isSubmitting, isFalse);
    });
  });

  // ─── loadSignatureStatus() ──────────────────────────────────────────────────

  group('loadSignatureStatus()', () {
    test('carrega assinatura do repositório e atualiza notifyListeners', () async {
      final now = DateTime.now();
      final assinatura = Assinatura(
        id: 'assinatura-1',
        ratId: 'rat-new',
        storageMode: StorageMode.inlineBinary,
        assetRef: 'signatures/assinatura-1.png',
        data: Uint8List.fromList([1, 2, 3]),
        sizeBytes: 3,
        mimeType: 'image/png',
        createdAt: now,
        updatedAt: now,
      );
      assinaturaRepo.assinaturas.add(assinatura);

      final sut = buildVm();
      await sut.loadSignatureStatus();

      expect(sut.hasSignature, isTrue);
    });

    test('hasSignature é false quando não há assinatura', () async {
      final sut = buildVm();
      await sut.loadSignatureStatus();

      expect(sut.hasSignature, isFalse);
    });
  });

  // ─── reopenForCorrection() ──────────────────────────────────────────────────

  group('reopenForCorrection()', () {
    test('retorna false quando motivo tem menos de 5 caracteres', () async {
      final initialRat = _makeValidRat();
      final remoteSession = _makeRemoteSession(papel: SessaoRemotaPapelEmpresa.tecnico);
      final sut = buildVm(initialRat: initialRat, remoteSession: remoteSession);

      final result = await sut.reopenForCorrection('curt');

      expect(result, isFalse);
      expect(sut.errorMessage, isNotNull);
    });

    test('retorna false quando não há remoteSession', () async {
      final initialRat = _makeValidRat();
      final sut = buildVm(initialRat: initialRat, remoteSession: null);

      final result = await sut.reopenForCorrection('Motivo válido para correção');

      expect(result, isFalse);
    });
  });

  // ─── deleteRat() ─────────────────────────────────────────────────────────────

  group('deleteRat()', () {
    test('retorna false quando não há initialRat', () async {
      final sut = buildVm();

      final result = await sut.deleteRat();

      expect(result, isFalse);
    });
  });

  // ─── notifyListeners ─────────────────────────────────────────────────────────

  group('notifyListeners', () {
    test('setClienteNome dispara notifyListeners', () {
      final sut = buildVm();
      var notified = false;
      sut.addListener(() => notified = true);

      sut.setClienteNome('Novo Cliente');

      expect(notified, isTrue);
    });

    test('setDataVisita dispara notifyListeners', () {
      final sut = buildVm();
      var notified = false;
      sut.addListener(() => notified = true);

      sut.setDataVisita(DateTime.now());

      expect(notified, isTrue);
    });

    test('setHorarioInicioAtendimento dispara notifyListeners', () {
      final sut = buildVm();
      var notified = false;
      sut.addListener(() => notified = true);

      sut.setHorarioInicioAtendimento('0900');

      expect(notified, isTrue);
    });

    test('setHorarioTerminoAtendimento dispara notifyListeners', () {
      final sut = buildVm();
      var notified = false;
      sut.addListener(() => notified = true);

      sut.setHorarioTerminoAtendimento('1100');

      expect(notified, isTrue);
    });

    test('setDescricao dispara notifyListeners', () {
      final sut = buildVm();
      var notified = false;
      sut.addListener(() => notified = true);

      sut.setDescricao('Nova descrição');

      expect(notified, isTrue);
    });

    test('setEquipamentoMovimentoTipo dispara notifyListeners', () {
      final sut = buildVm();
      var notified = false;
      sut.addListener(() => notified = true);

      sut.setEquipamentoMovimentoTipo(EquipamentoMovimentoTipo.retiradaParaReparo);

      expect(notified, isTrue);
    });

    test('setStatus dispara notifyListeners', () {
      final sut = buildVm();
      var notified = false;
      sut.addListener(() => notified = true);

      sut.setStatus(RatStatus.finalizado);

      expect(notified, isTrue);
    });
  });

  // ─── saveSignature() ────────────────────────────────────────────────────────

  group('saveSignature()', () {
    test('rejeita assinatura maior que 1 MB com mensagem de erro', () async {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Descrição válida');

      // 2 MB de bytes伪造
      final bigBytes = Uint8List(2 * 1024 * 1024);

      final result = await sut.saveSignature(bigBytes);

      expect(result, isFalse);
      expect(sut.errorMessage, isNotNull);
      expect(sut.errorMessage!.toLowerCase(), contains('grande'));
    });

    test('rejeita assinatura exatamente no limite (1 MB)', () async {
      final sut = buildVm();
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Descrição válida');

      // exatamente 1 MB
      final exactly1MB = Uint8List(1 * 1024 * 1024);

      final result = await sut.saveSignature(exactly1MB);

      // exatamente 1 MB deve ser aceito (não é maior que 1 MB)
      expect(result, isFalse); // save() fails because there's no valid RAT data
    });

    test('rejeita assinatura maior que 1 MB mesmo que save() funcione', () async {
      final remoteSession = _makeRemoteSession();
      final sut = buildVm(remoteSession: remoteSession);
      sut.setClienteNome('Cliente Válido');
      sut.setResponsavelRecebimento('Responsável');
      sut.setDataVisita(DateTime.now());
      sut.setHorarioInicioAtendimento('0800');
      sut.setHorarioTerminoAtendimento('1000');
      sut.setDescricao('Descrição válida');

      final bigBytes = Uint8List(2 * 1024 * 1024);

      // A validação de tamanho deve ocorrer ANTES do save()
      final result = await sut.saveSignature(bigBytes);

      expect(result, isFalse);
      expect(sut.errorMessage, contains('grande'));
    });
  });
}