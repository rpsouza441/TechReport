import 'package:flutter/foundation.dart';

import '../../domain/entities/rat.dart';
import '../../domain/repositories/rat_repository.dart';

class RatFormViewModel extends ChangeNotifier {
  RatFormViewModel({required RatRepository ratRepository, Rat? initialRat})
    : _ratRepository = ratRepository,
      _initialRat = initialRat,
      clienteNome = initialRat?.clienteNome ?? '',
      descricao = initialRat?.descricao ?? '',
      status = initialRat?.status ?? RatStatus.draft;

  final RatRepository _ratRepository;
  final Rat? _initialRat;

  String clienteNome;
  String descricao;
  RatStatus status;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _initialRat != null;

  void setClienteNome(String value) {
    clienteNome = value;
    notifyListeners();
  }

  void setDescricao(String value) {
    descricao = value;
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

    if (descricao.trim().isEmpty) {
      return 'Informe a descricao.';
    }

    return null;
  }

  Future<void> submit() async {
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final rat = Rat(
      id: _initialRat?.id ?? 'rat-${now.microsecondsSinceEpoch}',
      authorId: _initialRat?.authorId ?? 'tec-local-001',
      ownerType: _initialRat?.ownerType ?? RatOwnerType.localTecnico,
      numero: _initialRat?.numero ?? 'RAT-${now.millisecondsSinceEpoch}',
      clienteNome: clienteNome.trim(),
      descricao: descricao.trim(),
      status: status,
      syncStatus: _initialRat?.syncStatus ?? RatSyncStatus.localOnly,
      createdAt: _initialRat?.createdAt ?? now,
      updatedAt: now,
      deletedAt: _initialRat?.deletedAt,
    );

    await _ratRepository.save(rat);

    _isSubmitting = false;
    notifyListeners();
  }
}
