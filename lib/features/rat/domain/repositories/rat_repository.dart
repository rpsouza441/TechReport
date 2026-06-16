import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/presentation/view_models/rat_list_scope.dart';

abstract class RatRepository {
  Future<Rat?> getById(String id);

  Future<Rat?> getByIdScoped({required String id, required RatListScope scope});

  Future<List<Rat>> listLocal();

  Future<List<Rat>> listLocalPage({required int limit, required int offset});

  Future<List<Rat>> listCompanyForTechnician({
    required String empresaId,
    required String tecnicoId,
  });

  Future<List<Rat>> listCompanyForTechnicianPage({
    required String empresaId,
    required String tecnicoId,
    required int limit,
    required int offset,
  });

  Future<List<Rat>> listCompanyForManager({required String empresaId});

  Future<List<Rat>> listCompanyForManagerPage({
    required String empresaId,
    required int limit,
    required int offset,
  });

  // Cursor-based pagination methods
  Future<List<Rat>> listLocalCursor({required int limit, String? lastId});

  Future<List<Rat>> listCompanyForTechnicianCursor({
    required String empresaId,
    required String tecnicoId,
    required int limit,
    String? lastId,
  });

  Future<List<Rat>> listCompanyForManagerCursor({
    required String empresaId,
    required int limit,
    String? lastId,
  });

  Future<void> save(Rat rat);

  Future<void> update(Rat rat);
}
