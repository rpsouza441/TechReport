import 'package:flutter/foundation.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

import '../../domain/entities/rat.dart';
import '../../domain/repositories/rat_repository.dart';

class RatListViewModel extends ChangeNotifier {
  RatListViewModel({
    required AssinaturaRepository assinaturaRepository,
    required RatRepository ratRepository,
    required RatListScope scope,
  }) : _assinaturaRepository = assinaturaRepository,
       _ratRepository = ratRepository,
       _scope = scope;

  final AssinaturaRepository _assinaturaRepository;
  final RatRepository _ratRepository;
  final RatListScope _scope;

  List<Rat> _rats = [];
  Set<String> _signedRatIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Paginação
  static const int _pageSize = 30;
  int _offset = 0;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  // Filtros em memória
  String _query = '';
  RatStatus? _statusFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  List<Rat> get rats => _rats;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePages => _hasMorePages;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _rats.isEmpty;
  String get query => _query;
  RatStatus? get statusFilter => _statusFilter;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  RatListScope get scope => _scope;

  bool hasSignature(String ratId) {
    return _signedRatIds.contains(ratId);
  }

  void setQuery(String value) {
    _query = value;
    _resetPagination();
    notifyListeners();
  }

  void setStatusFilter(RatStatus? status) {
    _statusFilter = status;
    _resetPagination();
    notifyListeners();
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    _dateFrom = from;
    _dateTo = to;
    _resetPagination();
    notifyListeners();
  }

  void clearDateRange() {
    _dateFrom = null;
    _dateTo = null;
    _resetPagination();
    notifyListeners();
  }

  void clearAllFilters() {
    _query = '';
    _statusFilter = null;
    _dateFrom = null;
    _dateTo = null;
    _resetPagination();
    notifyListeners();
  }

  /// Lista filtrada em memória — nunca expande o escopo da sessão.
  List<Rat> get filteredRats {
    var list = _rats;

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (r) =>
                r.clienteNome.toLowerCase().contains(q) ||
                r.descricao.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_statusFilter != null) {
      list = list.where((r) => r.status == _statusFilter).toList();
    }

    if (_dateFrom != null) {
      list = list.where((r) {
        final date = r.dataVisita ?? r.createdAt;
        return !date.isBefore(_dateFrom!);
      }).toList();
    }

    if (_dateTo != null) {
      final endOfDay = DateTime(
        _dateTo!.year,
        _dateTo!.month,
        _dateTo!.day,
        23,
        59,
        59,
      );
      list = list.where((r) {
        final date = r.dataVisita ?? r.createdAt;
        return !date.isAfter(endOfDay);
      }).toList();
    }

    return list;
  }

  Future<void> load() async {
    _offset = 0;
    _hasMorePages = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _fetchPage(_pageSize, 0);
      _rats = page;
      _hasMorePages = page.length == _pageSize;

      _signedRatIds = await _loadSignedRatIds(_rats);
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar os RATs.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMorePages) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextOffset = _offset + _pageSize;
      final page = await _fetchPage(_pageSize, nextOffset);

      _rats = [..._rats, ...page];
      _offset = nextOffset;
      _hasMorePages = page.length == _pageSize;

      final moreIds = await _loadSignedRatIds(page);
      _signedRatIds = {..._signedRatIds, ...moreIds};
    } catch (_) {
      // Silently fail — user can scroll again to retry
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  void _resetPagination() {
    _offset = 0;
    _hasMorePages = true;
    _rats = [];
  }

  Future<List<Rat>> _fetchPage(int limit, int offset) async {
    switch (_scope.type) {
      case RatListScopeType.local:
        return _ratRepository.listLocalPage(limit: limit, offset: offset);
      case RatListScopeType.companyTechnician:
        return _ratRepository.listCompanyForTechnicianPage(
          empresaId: _scope.empresaId!,
          tecnicoId: _scope.tecnicoId!,
          limit: limit,
          offset: offset,
        );
      case RatListScopeType.companyManager:
        return _ratRepository.listCompanyForManagerPage(
          empresaId: _scope.empresaId!,
          limit: limit,
          offset: offset,
        );
    }
  }

  Future<Set<String>> _loadSignedRatIds(List<Rat> rats) async {
    if (rats.isEmpty) return {};

    final ratIds = rats.map((r) => r.id).toList();
    final assinaturaMap = await _assinaturaRepository.listByRatIds(ratIds);

    return assinaturaMap.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toSet();
  }
}