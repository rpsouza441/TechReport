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

  // Filtros em memória
  String _query = '';
  RatStatus? _statusFilter;

  List<Rat> get rats => _rats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _rats.isEmpty;
  String get query => _query;
  RatStatus? get statusFilter => _statusFilter;
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

    return list;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (_scope.type) {
        case RatListScopeType.local:
          _rats = await _ratRepository.listLocal();
        case RatListScopeType.companyTechnician:
          _rats = await _ratRepository.listCompanyForTechnician(
            empresaId: _scope.empresaId!,
            tecnicoId: _scope.tecnicoId!,
          );
        case RatListScopeType.companyManager:
          _rats = await _ratRepository.listCompanyForManager(
            empresaId: _scope.empresaId!,
          );
      }

      _signedRatIds = await _loadSignedRatIds(_rats);
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar os RATs.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Set<String>> _loadSignedRatIds(List<Rat> rats) async {
    final signedIds = <String>{};

    for (final rat in rats) {
      final assinaturas = await _assinaturaRepository.listByRatId(rat.id);
      if (assinaturas.isNotEmpty) {
        signedIds.add(rat.id);
      }
    }

    return signedIds;
  }
}
