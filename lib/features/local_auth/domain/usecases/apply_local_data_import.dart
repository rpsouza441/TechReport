import 'dart:convert';

import 'package:techreport/features/local_auth/domain/entities/local_import_result.dart';
import 'package:techreport/features/rat/domain/entities/rat.dart';
import 'package:techreport/features/rat/domain/repositories/rat_repository.dart';
import 'package:techreport/features/signature/data/services/local_signature_asset_store.dart';
import 'package:techreport/features/signature/domain/entities/assinatura.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';

enum LocalImportConflictPolicy { skip, overwrite }

class ApplyLocalDataImport {
  ApplyLocalDataImport({
    required RatRepository ratRepository,
    required AssinaturaRepository assinaturaRepository,
    required LocalSignatureAssetStore localSignatureAssetStore,
  }) : _ratRepository = ratRepository,
       _assinaturaRepository = assinaturaRepository,
       _localSignatureAssetStore = localSignatureAssetStore;

  final RatRepository _ratRepository;
  final AssinaturaRepository _assinaturaRepository;
  final LocalSignatureAssetStore _localSignatureAssetStore;

  Future<LocalImportResult> call({
    required Map<String, dynamic> payload,
    required LocalImportConflictPolicy conflictPolicy,
  }) async {
    final rats = payload['rats'] as List;
    final assinaturas = payload['assinaturas'] as List;
    final allowedRatIdsForSignature = <String>{};

    var importedRats = 0;
    var ignoredDuplicates = 0;
    var skippedConflicts = 0;
    var overwrittenConflicts = 0;

    for (final item in rats) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final rat = _ratFromJson(item);
      if (rat == null) {
        continue;
      }

      final existing = await _ratRepository.getById(rat.id);
      if (existing == null || existing.deletedAt != null) {
        await _ratRepository.save(rat);
        allowedRatIdsForSignature.add(rat.id);
        importedRats++;
        continue;
      }

      if (existing.updatedAt.isAtSameMomentAs(rat.updatedAt)) {
        allowedRatIdsForSignature.add(rat.id);
        ignoredDuplicates++;
        continue;
      }

      switch (conflictPolicy) {
        case LocalImportConflictPolicy.skip:
          skippedConflicts++;
        case LocalImportConflictPolicy.overwrite:
          await _ratRepository.save(rat);
          allowedRatIdsForSignature.add(rat.id);
          overwrittenConflicts++;
      }
    }

    var importedAssinaturas = 0;
    for (final item in assinaturas) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final assinatura = await _assinaturaFromJson(
        item,
        allowedRatIds: allowedRatIdsForSignature,
      );
      if (assinatura == null) {
        continue;
      }

      final existing = await _assinaturaRepository.getById(assinatura.id);
      if (existing != null &&
          existing.deletedAt == null &&
          existing.updatedAt.isAtSameMomentAs(assinatura.updatedAt)) {
        continue;
      }

      await _assinaturaRepository.save(assinatura);
      importedAssinaturas++;
    }

    return LocalImportResult(
      importedRats: importedRats,
      ignoredDuplicates: ignoredDuplicates,
      skippedConflicts: skippedConflicts,
      overwrittenConflicts: overwrittenConflicts,
      importedAssinaturas: importedAssinaturas,
    );
  }

  Rat? _ratFromJson(Map<String, dynamic> json) {
    try {
      return Rat(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        empresaId: json['empresaId'] as String?,
        usuarioId: json['usuarioId'] as String?,
        tecnicoId: json['tecnicoId'] as String?,
        ownerType: RatOwnerType.values.byName(json['ownerType'] as String),
        numero: json['numero'] as String,
        clienteNome: json['clienteNome'] as String,
        responsavelRecebimento: json['responsavelRecebimento'] as String?,
        dataVisita: _optionalDate(json['dataVisita'] as String?),
        horarioInicioAtendimento: json['horarioInicioAtendimento'] as String?,
        horarioTerminoAtendimento: json['horarioTerminoAtendimento'] as String?,
        descricao: json['descricao'] as String,
        equipamentoMovimentoTipo: _optionalEnum(
          json['equipamentoMovimentoTipo'] as String?,
          EquipamentoMovimentoTipo.values,
        ),
        equipamentoDescricao: json['equipamentoDescricao'] as String?,
        equipamentoObservacao: json['equipamentoObservacao'] as String?,
        status: RatStatus.values.byName(json['status'] as String),
        syncStatus: RatSyncStatus.values.byName(json['syncStatus'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: _optionalDate(json['deletedAt'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Assinatura?> _assinaturaFromJson(
    Map<String, dynamic> json, {
    required Set<String> allowedRatIds,
  }) async {
    try {
      final ratId = json['ratId'] as String;
      final bytesBase64 = json['assetBytesBase64'] as String?;
      if (!allowedRatIds.contains(ratId) ||
          bytesBase64 == null ||
          bytesBase64.isEmpty) {
        return null;
      }

      final id = json['id'] as String;
      final assetRef = await _localSignatureAssetStore.savePng(
        assinaturaId: id,
        bytes: base64Decode(bytesBase64),
      );

      return Assinatura(
        id: id,
        ratId: ratId,
        storageMode: StorageMode.localFile,
        assetRef: assetRef,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: _optionalDate(json['deletedAt'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _optionalDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  T? _optionalEnum<T extends Enum>(String? value, List<T> values) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final enumValue in values) {
      if (enumValue.name == value) {
        return enumValue;
      }
    }

    return null;
  }
}
