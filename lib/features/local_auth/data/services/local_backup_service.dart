import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:techreport/features/local_auth/domain/entities/local_backup_manifest.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';

class LocalBackupService {
  LocalBackupService({
    required RatRepository ratRepository,
    required AssinaturaRepository assinaturaRepository,
    required LocalSignatureAssetStore localSignatureAssetStore,
  }) : _ratRepository = ratRepository,
       _assinaturaRepository = assinaturaRepository,
       _localSignatureAssetStore = localSignatureAssetStore;

  final RatRepository _ratRepository;
  final AssinaturaRepository _assinaturaRepository;
  final LocalSignatureAssetStore _localSignatureAssetStore;

  Future<Uint8List> exportBackup() async {
    final rats = await _ratRepository.listLocal();
    final allAssinaturas = <Assinatura>[];

    for (final rat in rats) {
      final assinaturas = await _assinaturaRepository.listByRatId(rat.id);
      allAssinaturas.addAll(assinaturas);
    }

    final ratsJson = _ratsToJson(rats);
    final assinaturasJson = await _assinaturasToJson(allAssinaturas);

    final ratsBytes = utf8.encode(_jsonEncode(ratsJson));
    final assinaturasBytes = utf8.encode(_jsonEncode(assinaturasJson));

    final ratsChecksum = sha256.convert(ratsBytes).toString();
    final assinaturasChecksum = sha256.convert(assinaturasBytes).toString();

    final packageInfo = await PackageInfo.fromPlatform();
    const dbSchemaVersion = 8;

    final manifest = LocalBackupManifest(
      schema: 'techreport.backup.v1',
      createdAt: DateTime.now(),
      appVersion: packageInfo.version,
      databaseSchemaVersion: dbSchemaVersion,
      counts: Counts(rats: rats.length, assinaturas: allAssinaturas.length),
      checksums: {
        'data/rats.json': ratsChecksum,
        'data/assinaturas.json': assinaturasChecksum,
      },
    );

    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );

    final archive = Archive();
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );
    archive.addFile(ArchiveFile('data/rats.json', ratsBytes.length, ratsBytes));
    archive.addFile(
      ArchiveFile(
        'data/assinaturas.json',
        assinaturasBytes.length,
        assinaturasBytes,
      ),
    );

    final List<int> zipBytes = ZipEncoder().encode(archive);

    return Uint8List.fromList(zipBytes);
  }

  Future<String?> saveBackupToDevice() async {
    final bytes = await exportBackup();
    final fileName = _backupFileName();

    return FilePicker.saveFile(
      dialogTitle: 'Salvar backup TechReport',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['techreport-backup'],
      bytes: bytes,
    );
  }

  Future<void> shareBackup() async {
    final bytes = await exportBackup();
    final file = await _saveTemporaryZip(bytes);

    await SharePlus.instance.share(
      ShareParams(
        subject: 'Backup TechReport',
        text: 'Backup TechReport',
        files: [XFile(file.path)],
      ),
    );
  }

  List<Map<String, Object?>> _ratsToJson(List<Rat> rats) {
    return rats.map((rat) {
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
    }).toList();
  }

  Future<List<Map<String, Object?>>> _assinaturasToJson(
    List<Assinatura> assinaturas,
  ) async {
    final result = <Map<String, Object?>>[];

    for (final assinatura in assinaturas) {
      Uint8List? bytes;

      if (assinatura.storageMode == StorageMode.inlineBinary) {
        bytes = await _assinaturaRepository.readBytes(assinatura.id);
      } else if (assinatura.storageMode == StorageMode.localFile) {
        bytes = await _localSignatureAssetStore.read(assinatura.assetRef);
      }

      result.add(<String, Object?>{
        'id': assinatura.id,
        'ratId': assinatura.ratId,
        'storageMode': assinatura.storageMode.name,
        'assetRef': assinatura.assetRef,
        'assetBytesBase64': bytes == null ? null : base64Encode(bytes),
        'assetMissing': bytes == null,
        'createdAt': assinatura.createdAt.toIso8601String(),
        'updatedAt': assinatura.updatedAt.toIso8601String(),
        'deletedAt': assinatura.deletedAt?.toIso8601String(),
      });
    }

    return result;
  }

  Future<File> _saveTemporaryZip(Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${_backupFileName()}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _backupFileName() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 14);
    return 'techreport-backup-$timestamp.techreport-backup';
  }

  String _jsonEncode(Object value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}
