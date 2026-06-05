import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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

  Future<String?> saveExportToDevice() async {
    final json = await buildExportJson();
    final fileName = _exportFileName();
    final bytes = Uint8List.fromList(utf8.encode(json));

    return FilePicker.saveFile(
      dialogTitle: 'Salvar backup local TechReport',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
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
      'responsavelDocumento': rat.responsavelDocumento,
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
    Uint8List? bytes;

    if (assinatura.storageMode == StorageMode.inlineBinary) {
      bytes = await _assinaturaRepository.readBytes(assinatura.id);
    } else if (assinatura.storageMode == StorageMode.localFile) {
      bytes = await _localSignatureAssetStore.read(assinatura.assetRef);
    }

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
    final file = File(
      '${directory.path}${Platform.pathSeparator}${_exportFileName()}',
    );

    await file.writeAsString(json, flush: true);
    return file;
  }

  String _exportFileName() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 14);

    return 'techreport-local-export-$timestamp.json';
  }
}