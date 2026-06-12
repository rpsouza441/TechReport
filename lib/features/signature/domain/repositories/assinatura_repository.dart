import 'dart:typed_data';

import 'package:techreport/features/signature/domain/entities/assinatura.dart';

abstract class AssinaturaRepository {
  Future<Assinatura?> getById(String id);

  Future<List<Assinatura>> listByRatId(String ratId);

  /// Busca todas as assinaturas de múltiplos RATs em uma única query.
  /// Retorna mapa de ratId -> lista de assinaturas (vazio para RATs sem assinatura).
  Future<Map<String, List<Assinatura>>> listByRatIds(List<String> ratIds);

  Future<void> save(Assinatura assinatura);

  Future<void> update(Assinatura assinatura);

  Future<void> delete(String id);

  Future<Uint8List?> readBytes(String id);

  Future<void> saveBytes({
    required String assinaturaId,
    required Uint8List bytes,
    required String assetRef,
    required String ratId,
  });
}
