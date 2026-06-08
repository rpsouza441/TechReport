import '../repositories/tecnico_local_repository.dart';

class UpdateTecnicoLocal {
  UpdateTecnicoLocal(this._repository);

  final TecnicoLocalRepository _repository;

  Future<void> call({
    required String nome,
    required String email,
  }) async {
    final current = await _repository.getCurrent();
    if (current == null) return;

    await _repository.save(
      current.copyWith(
        nome: nome.trim(),
        email: email.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
