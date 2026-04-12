import '../entities/tecnico_local.dart';

abstract class TecnicoLocalRepository {
  Future<TecnicoLocal?> getCurrent();

  Future<void> save(TecnicoLocal tecnicoLocal);
}
