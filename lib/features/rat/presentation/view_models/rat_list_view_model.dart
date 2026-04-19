import 'package:flutter/foundation.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

import '../../domain/entities/rat.dart';
import '../../domain/repositories/rat_repository.dart';

class RatListViewModel extends ChangeNotifier {
  RatListViewModel({
    required AssinaturaRepository assinaturaRepository,
    required RatRepository ratRepository,
  }) : _assinaturaRepository = assinaturaRepository,
       _ratRepository = ratRepository;

  final AssinaturaRepository _assinaturaRepository;
  final RatRepository _ratRepository;

  List<Rat> _rats = [];
  Set<String> _signedRatIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Rat> get rats => _rats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _rats.isEmpty;

  bool hasSignature(String ratId) {
    return _signedRatIds.contains(ratId);
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rats = await _ratRepository.listAll();
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
