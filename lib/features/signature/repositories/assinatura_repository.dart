import 'package:techreport/features/signature/entities/assinatura.dart';

abstract class AssinaturaRepository {
  Future<Assinatura?> getById(String id);

  Future<List<Assinatura>> listByRatId(String ratId);

  Future<void> save(Assinatura assinatura);

  Future<void> update(Assinatura assinatura);

  Future<void> delete(String id);
}
