import 'package:techreport/features/rat/domain/entities/rat.dart';

abstract class RatRepository {
  Future<Rat?> getById(String id);

  Future<List<Rat>> listAll();

  Future<void> save(Rat rat);

  Future<void> update(Rat rat);
}
