import 'package:techreport/features/rat/domain/entities/rat.dart';

abstract class RatRepository {
  Future<Rat?> getById(String id);

  Future<List<Rat>> listLocal();

  Future<List<Rat>> listCompanyForTechnician({
    required String empresaId,
    required String tecnicoId,
  });

  Future<List<Rat>> listCompanyForManager({required String empresaId});

  Future<void> save(Rat rat);

  Future<void> update(Rat rat);
}
