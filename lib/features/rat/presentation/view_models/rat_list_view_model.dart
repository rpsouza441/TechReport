import 'package:flutter/foundation.dart';

import '../../domain/entities/rat.dart';
import '../../domain/repositories/rat_repository.dart';

class RatListViewModel extends ChangeNotifier {
  RatListViewModel({required RatRepository ratRepository})
    : _ratRepository = ratRepository;

  final RatRepository _ratRepository;

  List<Rat> _rats = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Rat> get rats => _rats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _rats.isEmpty;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rats = await _ratRepository.listAll();
    } catch (_) {
      _errorMessage = 'Nao foi possivel carregar os RATs.';
    }

    _isLoading = false;
    notifyListeners();
  }
}
