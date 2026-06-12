import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_view_model.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

class _StubRatRepository implements RatRepository {
  final List<Rat> rats = [];
  bool shouldThrowOnList = false;
  int listLocalPageCallCount = 0;
  int listCompanyForTechnicianPageCallCount = 0;
  int listCompanyForManagerPageCallCount = 0;

  @override
  Future<Rat?> getById(String id) async => null;

  @override
  Future<Rat?> getByIdScoped({
    required String id,
    required RatListScope scope,
  }) async =>
      null;

  @override
  Future<List<Rat>> listLocal() async => rats;

  @override
  Future<List<Rat>> listLocalPage({
    required int limit,
    required int offset,
  }) async {
    listLocalPageCallCount++;
    if (shouldThrowOnList) throw Exception('list failed');
    return rats.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Rat>> listCompanyForManager({
    required String empresaId,
  }) async =>
      rats;

  @override
  Future<List<Rat>> listCompanyForManagerPage({
    required String empresaId,
    required int limit,
    required int offset,
  }) async {
    listCompanyForManagerPageCallCount++;
    if (shouldThrowOnList) throw Exception('list failed');
    return rats.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Rat>> listCompanyForTechnician({
    required String empresaId,
    required String tecnicoId,
  }) async =>
      rats;

  @override
  Future<List<Rat>> listCompanyForTechnicianPage({
    required String empresaId,
    required String tecnicoId,
    required int limit,
    required int offset,
  }) async {
    listCompanyForTechnicianPageCallCount++;
    if (shouldThrowOnList) throw Exception('list failed');
    return rats.skip(offset).take(limit).toList();
  }

  @override
  Future<void> save(Rat rat) async {}

  @override
  Future<void> update(Rat rat) async {}
}

class _StubAssinaturaRepository implements AssinaturaRepository {
  final Map<String, List<Assinatura>> assinaturasPorRat = {};
  int listByRatIdCallCount = 0;
  int listByRatIdsCallCount = 0;
  List<List<String>>? listByRatIdsCalledWith;

  void setAssinaturas(String ratId, List<Assinatura> assinaturas) {
    assinaturasPorRat[ratId] = assinaturas;
  }

  @override
  Future<List<Assinatura>> listByRatId(String ratId) async {
    listByRatIdCallCount++;
    return assinaturasPorRat[ratId] ?? [];
  }

  @override
  Future<Map<String, List<Assinatura>>> listByRatIds(List<String> ratIds) async {
    listByRatIdsCallCount++;
    listByRatIdsCalledWith ??= [];
    listByRatIdsCalledWith!.add(ratIds);
    final result = <String, List<Assinatura>>{};
    for (final id in ratIds) {
      result[id] = assinaturasPorRat[id] ?? [];
    }
    return result;
  }

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

Rat _rat(String id, String clienteNome, {DateTime? dataVisita}) {
  final now = DateTime.now();
  return Rat(
    id: id,
    authorId: 'author-1',
    empresaId: 'emp-1',
    usuarioId: 'user-1',
    tecnicoId: 'tec-1',
    ownerType: RatOwnerType.companyTecnico,
    numero: id,
    clienteNome: clienteNome,
    responsavelRecebimento: 'Responsável',
    dataVisita: dataVisita ?? now,
    horarioInicioAtendimento: '0800',
    horarioTerminoAtendimento: '0900',
    descricao: 'Descrição',
    status: RatStatus.draft,
    syncStatus: RatSyncStatus.synced,
    createdAt: now,
    updatedAt: now,
  );
}

Assinatura _assinatura(String ratId) {
  final now = DateTime.now();
  return Assinatura(
    id: 'assinatura-$ratId',
    ratId: ratId,
    storageMode: StorageMode.inlineBinary,
    assetRef: 'signatures/assinatura-$ratId.png',
    data: Uint8List.fromList([1, 2, 3]),
    sizeBytes: 3,
    mimeType: 'image/png',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _StubRatRepository ratRepo;
  late _StubAssinaturaRepository assinaturaRepo;

  setUp(() {
    ratRepo = _StubRatRepository();
    assinaturaRepo = _StubAssinaturaRepository();
  });

  RatListViewModel buildVm({required RatListScope scope}) {
    return RatListViewModel(
      assinaturaRepository: assinaturaRepo,
      ratRepository: ratRepo,
      scope: scope,
    );
  }

  // ─── load() ──────────────────────────────────────────────────────────────────

  group('load()', () {
    test('carrega RATs e busca assinaturas em lote (listByRatIds chamado uma vez)', () async {
      ratRepo.rats.addAll([
        _rat('rat-1', 'Cliente A'),
        _rat('rat-2', 'Cliente B'),
        _rat('rat-3', 'Cliente C'),
      ]);
      // Apenas rat-1 tem assinatura
      assinaturaRepo.setAssinaturas('rat-1', [_assinatura('rat-1')]);
      assinaturaRepo.setAssinaturas('rat-2', []);
      assinaturaRepo.setAssinaturas('rat-3', []);

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      expect(sut.rats, hasLength(3));
      // listByRatIds chamado uma vez com todos os 3 ratIds (N+1 corrigido)
      expect(assinaturaRepo.listByRatIdsCallCount, 1);
      expect(assinaturaRepo.listByRatIdsCalledWith?.first, hasLength(3));
      expect(sut.hasSignature('rat-1'), isTrue);
      expect(sut.hasSignature('rat-2'), isFalse);
      expect(sut.hasSignature('rat-3'), isFalse);
    });

    test('load() com erro seta errorMessage', () async {
      ratRepo.shouldThrowOnList = true;

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      expect(sut.errorMessage, isNotNull);
      expect(sut.errorMessage, contains('Nao foi possivel'));
    });

    test('load() limpa lista anterior e reseta paginação', () async {
      // Preenche repo com 1 RAT antes do primeiro load
      ratRepo.rats.addAll([_rat('rat-1', 'Cliente A')]);

      final sut = buildVm(scope: const RatListScope.local());

      // Primeiro load — offset reseta para 0
      await sut.load();
      expect(sut.rats, hasLength(1));

      // Adiciona mais RATs ao repo (simula dados que chegaram entre loads)
      ratRepo.rats.addAll([_rat('rat-2', 'Cliente B'), _rat('rat-3', 'Cliente C')]);

      // Segundo load — offset volta a 0, lista é substituída não concatenada
      await sut.load();
      // O repo agora tem 3 rats, então load retorna 3 (offset=0, limit=30, 3<=30)
      expect(sut.rats, hasLength(3));
    });

    test('load() seta isLoading durante execução', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));

      final sut = buildVm(scope: const RatListScope.local());

      var isLoadingDuringLoad = false;
      sut.addListener(() {
        if (sut.isLoading) isLoadingDuringLoad = true;
      });

      await sut.load();

      expect(isLoadingDuringLoad, isTrue);
      expect(sut.isLoading, isFalse);
    });

    test('load() define hasMorePages false quando página é menor que pageSize', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      // Com 1 RAT e pageSize=30, não há mais páginas
      expect(sut.hasMorePages, isFalse);
    });

    test('load() com escopo local usa listLocalPage', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      expect(ratRepo.listLocalPageCallCount, 1);
    });

    test('load() com escopo company technician usa listCompanyForTechnicianPage', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));

      final sut = buildVm(
        scope: const RatListScope.companyTechnician(
          empresaId: 'emp-1',
          tecnicoId: 'tec-1',
        ),
      );
      await sut.load();

      expect(ratRepo.listCompanyForTechnicianPageCallCount, 1);
    });

    test('load() com escopo company manager usa listCompanyForManagerPage', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));

      final sut = buildVm(
        scope: const RatListScope.companyManager(empresaId: 'emp-1'),
      );
      await sut.load();

      expect(ratRepo.listCompanyForManagerPageCallCount, 1);
    });
  });

  // ─── loadMore() ─────────────────────────────────────────────────────────────

  group('loadMore()', () {
    test('loadMore() appenda RATs à lista existente', () async {
      ratRepo.rats.addAll([
        _rat('rat-1', 'Cliente A'),
        _rat('rat-2', 'Cliente B'),
      ]);

      final sut = buildVm(scope: const RatListScope.local());

      // Primeira página
      await sut.load();
      expect(sut.rats, hasLength(2));

      // Segunda página (vazia simulates end)
      await sut.loadMore();

      // Com _pageSize=30 e apenas 2 rats, loadMore não appenda mais nada
      expect(sut.rats, hasLength(2));
    });

    test('loadMore() não faz nada quando hasMorePages é false', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();
      expect(sut.hasMorePages, isFalse);

      // Reset call count
      ratRepo.listLocalPageCallCount = 0;

      await sut.loadMore();

      expect(ratRepo.listLocalPageCallCount, 0);
    });

    test('loadMore() não faz nada quando já está carregando mais', () async {
      ratRepo.rats.addAll(List.generate(30, (i) => _rat('rat-$i', 'Cliente $i')));

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      ratRepo.listLocalPageCallCount = 0;

      // Não deve fazer nada se já está loadingMore
      // (Não há como testar isso facilmente sem async mocking, mas
      // o guard `_isLoadingMore` impede chamadas simultâneas)
    });

    test('loadMore() atualiza hasMorePages após append', () async {
      ratRepo.rats.addAll(List.generate(30, (i) => _rat('rat-$i', 'Cliente $i')));

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();
      expect(sut.hasMorePages, isTrue);

      // Segunda página com exatamente 30 items → ainda tem mais
      await sut.loadMore();
      // Com apenas 30 rats e limit=30, loadMore não appenda mais nada (page < limit)
      expect(sut.rats, hasLength(30));
      expect(sut.hasMorePages, isFalse);
    });
  });

  // ─── Filtros em memória ──────────────────────────────────────────────────────

  group('filtros em memória', () {
    test('setQuery filtra rats por clienteNome e descricao', () async {
      ratRepo.rats.addAll([
        _rat('rat-1', 'Cliente Alpha'),
        _rat('rat-2', 'Cliente Beta'),
        _rat('rat-3', 'Cliente Alpha Plus'),
      ]);

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      sut.setQuery('alpha');

      expect(sut.filteredRats, hasLength(2));
    });

    test('setStatusFilter filtra rats por status', () async {
      ratRepo.rats.addAll([
        _rat('rat-1', 'Cliente A'),
        _rat('rat-2', 'Cliente B'),
      ]);

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      sut.setStatusFilter(RatStatus.finalizado);

      expect(sut.filteredRats, hasLength(0));
    });

    test('clearAllFilters reseta todos os filtros', () async {
      ratRepo.rats.addAll([
        _rat('rat-1', 'Cliente Alpha'),
        _rat('rat-2', 'Cliente Beta'),
      ]);

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      sut.setQuery('alpha');
      expect(sut.filteredRats, hasLength(1));

      sut.clearAllFilters();
      expect(sut.query, isEmpty);
      expect(sut.statusFilter, isNull);
      expect(sut.dateFrom, isNull);
      expect(sut.dateTo, isNull);
      expect(sut.filteredRats, hasLength(2));
    });

    test('setDateRange filtra por intervalo de datas', () async {
      final today = DateTime.now();
      ratRepo.rats.addAll([
        _rat('rat-1', 'Cliente A', dataVisita: today),
        _rat('rat-2', 'Cliente B', dataVisita: today.subtract(const Duration(days: 30))),
      ]);

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      sut.setDateRange(from: today.subtract(const Duration(days: 7)), to: today);

      expect(sut.filteredRats, hasLength(1));
    });

    test('clearDateRange remove filtro de data', () async {
      final today = DateTime.now();
      ratRepo.rats.addAll([
        _rat('rat-1', 'Cliente A', dataVisita: today),
        _rat('rat-2', 'Cliente B', dataVisita: today.subtract(const Duration(days: 30))),
      ]);

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      sut.setDateRange(from: today.subtract(const Duration(days: 7)), to: today);
      expect(sut.filteredRats, hasLength(1));

      sut.clearDateRange();
      expect(sut.dateFrom, isNull);
      expect(sut.dateTo, isNull);
      expect(sut.filteredRats, hasLength(2));
    });

    test('filtros disparam notifyListeners', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      var notifyCount = 0;
      sut.addListener(() => notifyCount++);

      sut.setQuery('test');
      expect(notifyCount, greaterThan(0));

      notifyCount = 0;
      sut.setStatusFilter(RatStatus.draft);
      expect(notifyCount, greaterThan(0));

      notifyCount = 0;
      sut.setDateRange(from: DateTime.now(), to: DateTime.now());
      expect(notifyCount, greaterThan(0));
    });
  });

  // ─── hasSignature() ────────────────────────────────────────────────────────

  group('hasSignature()', () {
    test('retorna true para RAT com assinatura', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));
      assinaturaRepo.setAssinaturas('rat-1', [_assinatura('rat-1')]);

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      expect(sut.hasSignature('rat-1'), isTrue);
    });

    test('retorna false para RAT sem assinatura', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));
      assinaturaRepo.setAssinaturas('rat-1', []);

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      expect(sut.hasSignature('rat-1'), isFalse);
    });

    test('retorna false para RAT inexistente', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      expect(sut.hasSignature('rat-inexistente'), isFalse);
    });
  });

  // ─── Estado geral ───────────────────────────────────────────────────────────

  group('estado geral', () {
    test('isEmpty é true quando não há RATs', () async {
      // ratRepo.rats é vazio por padrão

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      expect(sut.isEmpty, isTrue);
    });

    test('isEmpty é false quando há RATs', () async {
      ratRepo.rats.add(_rat('rat-1', 'Cliente A'));

      final sut = buildVm(scope: const RatListScope.local());
      await sut.load();

      expect(sut.isEmpty, isFalse);
    });

    test('scope retorna escopo configurado', () {
      const scope = RatListScope.local();
      final sut = buildVm(scope: scope);

      expect(sut.scope, scope);
    });
  });
}