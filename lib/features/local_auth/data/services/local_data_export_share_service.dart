import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

class LocalDataExportShareService {
  LocalDataExportShareService({
    required RatRepository ratRepository,
    required AssinaturaRepository assinaturaRepository,
    required LocalSignatureAssetStore localSignatureAssetStore,
  }) : _ratRepository = ratRepository,
       _assinaturaRepository = assinaturaRepository,
       _localSignatureAssetStore = localSignatureAssetStore;

  final RatRepository _ratRepository;
  final AssinaturaRepository _assinaturaRepository;
  final LocalSignatureAssetStore _localSignatureAssetStore;

  Future<void> shareExport() async {
    final json = await buildExportJson();
    final file = await _saveTemporaryJson(json);

    await SharePlus.instance.share(
      ShareParams(
        subject: 'Backup local TechReport',
        text: 'Backup local TechReport',
        files: [XFile(file.path)],
      ),
    );
  }

  Future<String> buildExportJson() async {
    final rats = await _ratRepository.listLocal();
    final assinaturaMaps = <Map<String, Object?>>[];

    for (final rat in rats) {
      final assinaturas = await _assinaturaRepository.listByRatId(rat.id);
      for (final assinatura in assinaturas) {
        assinaturaMaps.add(await _assinaturaToJson(assinatura));
      }
    }

    final payload = <String, Object?>{
      'schema': 'techreport.local_export.v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'source': <String, Object?>{'app': 'TechReport', 'mode': 'local'},
      'rats': rats.map(_ratToJson).toList(),
      'assinaturas': assinaturaMaps,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Map<String, Object?> _ratToJson(Rat rat) {
    return <String, Object?>{
      'id': rat.id,
      'authorId': rat.authorId,
      'empresaId': rat.empresaId,
      'usuarioId': rat.usuarioId,
      'tecnicoId': rat.tecnicoId,
      'ownerType': rat.ownerType.name,
      'numero': rat.numero,
      'clienteNome': rat.clienteNome,
      'responsavelRecebimento': rat.responsavelRecebimento,
      'dataVisita': rat.dataVisita?.toIso8601String(),
      'horarioInicioAtendimento': rat.horarioInicioAtendimento,
      'horarioTerminoAtendimento': rat.horarioTerminoAtendimento,
      'descricao': rat.descricao,
      'equipamentoMovimentoTipo': rat.equipamentoMovimentoTipo?.name,
      'equipamentoDescricao': rat.equipamentoDescricao,
      'equipamentoObservacao': rat.equipamentoObservacao,
      'status': rat.status.name,
      'syncStatus': rat.syncStatus.name,
      'createdAt': rat.createdAt.toIso8601String(),
      'updatedAt': rat.updatedAt.toIso8601String(),
      'deletedAt': rat.deletedAt?.toIso8601String(),
    };
  }

  Future<Map<String, Object?>> _assinaturaToJson(Assinatura assinatura) async {
    final bytes = assinatura.storageMode == StorageMode.localFile
        ? await _localSignatureAssetStore.read(assinatura.assetRef)
        : null;

    return <String, Object?>{
      'id': assinatura.id,
      'ratId': assinatura.ratId,
      'storageMode': assinatura.storageMode.name,
      'assetRef': assinatura.assetRef,
      'assetBytesBase64': bytes == null ? null : base64Encode(bytes),
      'assetMissing': bytes == null,
      'createdAt': assinatura.createdAt.toIso8601String(),
      'updatedAt': assinatura.updatedAt.toIso8601String(),
      'deletedAt': assinatura.deletedAt?.toIso8601String(),
    };
  }

  Future<File> _saveTemporaryJson(String json) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 14);
    final file = File(
      '${directory.path}${Platform.pathSeparator}techreport-local-export-$timestamp.json',
    );

    await file.writeAsString(json, flush: true);
    return file;
  }
}
