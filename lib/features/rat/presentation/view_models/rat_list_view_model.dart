import 'package:flutter/foundation.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
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
  static const int _pageSize = 20;
  String? _lastId;
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
    notifyListeners();
  }

  void setStatusFilter(RatStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    _dateFrom = from;
    _dateTo = to;
    notifyListeners();
  }

  void clearDateRange() {
    _dateFrom = null;
    _dateTo = null;
    notifyListeners();
  }

  void clearAllFilters() {
    _query = '';
    _statusFilter = null;
    _dateFrom = null;
    _dateTo = null;
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
    _lastId = null;
    _hasMorePages = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _fetchPageCursor(_pageSize, null);
      _rats = page;
      _lastId = page.isNotEmpty ? page.last.id : null;
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
      final page = await _fetchPageCursor(_pageSize, _lastId);

      _rats = [..._rats, ...page];
      _lastId = page.isNotEmpty ? page.last.id : null;
      _hasMorePages = page.length == _pageSize;

      final moreIds = await _loadSignedRatIds(page);
      _signedRatIds = {..._signedRatIds, ...moreIds};
    } catch (_) {
      // Silently fail — user can scroll again to retry
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<List<Rat>> _fetchPageCursor(int limit, String? lastId) async {
    switch (_scope.type) {
      case RatListScopeType.local:
        return _ratRepository.listLocalCursor(limit: limit, lastId: lastId);
      case RatListScopeType.companyTechnician:
        return _ratRepository.listCompanyForTechnicianCursor(
          empresaId: _scope.empresaId!,
          tecnicoId: _scope.tecnicoId!,
          limit: limit,
          lastId: lastId,
        );
      case RatListScopeType.companyManager:
        return _ratRepository.listCompanyForManagerCursor(
          empresaId: _scope.empresaId!,
          limit: limit,
          lastId: lastId,
        );
    }
  }

  Future<Set<String>> _loadSignedRatIds(List<Rat> rats) async {
    if (rats.isEmpty) return {};

    final ratIds = rats.map((r) => r.id).toList();
    final assinaturaMap = await _assinaturaRepository.listByRatIds(ratIds);

    return rats
        .where((rat) => _hasValidSignature(rat, assinaturaMap[rat.id] ?? []))
        .map((rat) => rat.id)
        .toSet();
  }

  bool _hasValidSignature(Rat rat, List<Assinatura> assinaturas) {
    if (assinaturas.isEmpty) return false;

    final invalidatedAt = rat.assinaturaInvalidadaEm;
    if (invalidatedAt == null) return true;

    return assinaturas.any(
      (assinatura) => assinatura.updatedAt.isAfter(invalidatedAt),
    );
  }
}
