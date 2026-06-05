import 'dart:convert';

import 'package:techreport/features/signature/data/repositories/supabase_remote_assinatura_repository.dart';
import 'package:techreport/features/signature/domain/repositories/assinatura_repository.dart';
import 'package:techreport/features/signature/domain/repositories/remote_assinatura_repository.dart';
import 'package:techreport/features/sync/domain/entities/sync_item.dart';

class ProcessAssinaturaSync {
  const ProcessAssinaturaSync({
    required AssinaturaRepository assinaturaRepository,
    required RemoteAssinaturaRepository remoteAssinaturaRepository,
  }) : _assinaturaRepository = assinaturaRepository,
       _remoteAssinaturaRepository = remoteAssinaturaRepository;

  final AssinaturaRepository _assinaturaRepository;
  final RemoteAssinaturaRepository _remoteAssinaturaRepository;

  Future<void> call(SyncItem item) async {
    final payload = _decodePayload(item.payload);

    final empresaId = payload['empresaId'] as String;
    final ratId = payload['ratId'] as String;
    final assinaturaId = payload['assinaturaId'] as String;
    final deletedAtStr = payload['deletedAt'] as String?;
    final deletedAt = deletedAtStr != null ? DateTime.parse(deletedAtStr) : null;

    if (item.operation == SyncOperation.delete) {
      await _remoteAssinaturaRepository.markDeleted(
        empresaId: empresaId,
        ratId: ratId,
        assinaturaId: assinaturaId,
      );
      return;
    }

    // upsert — le bytes do repositório local
    final bytes = await _assinaturaRepository.readBytes(assinaturaId);
    if (bytes == null) {
      // Assinatura pode ter sido removida entre enqueue e process
      return;
    }

    final mimeType = payload['mimeType'] as String? ?? 'image/png';
    const version = 1;
    final storagePath =
        '$empresaId/$ratId/$assinaturaId/v$version.png';
    final sha256 = SupabaseRemoteAssinaturaRepository.computeSha256(
      bytes,
    );

    // Upload do objeto
    await _remoteAssinaturaRepository.uploadSignature(
      empresaId: empresaId,
      ratId: ratId,
      assinaturaId: assinaturaId,
      version: version,
      bytes: bytes,
      mimeType: mimeType,
    );

    // Upsert de metadata
    await _remoteAssinaturaRepository.upsertMetadata(
      empresaId: empresaId,
      ratId: ratId,
      assinaturaId: assinaturaId,
      storagePath: storagePath,
      sha256: sha256,
      sizeBytes: bytes.length,
      mimeType: mimeType,
      version: version,
      deletedAt: deletedAt,
    );
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Payload de assinatura invalido.');
    }
    return decoded;
  }
}