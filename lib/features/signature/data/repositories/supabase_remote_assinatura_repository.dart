import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:techreport/features/company_auth/data/services/supabase_client_factory.dart';
import 'package:techreport/features/signature/domain/repositories/remote_assinatura_repository.dart';

class SupabaseRemoteAssinaturaRepository implements RemoteAssinaturaRepository {
  SupabaseRemoteAssinaturaRepository({
    required SupabaseClientFactory clientFactory,
  }) : _clientFactory = clientFactory;

  final SupabaseClientFactory _clientFactory;
  static const _bucket = 'rat-signatures';
  static const _expiresIn = 300; // 5 minutes

  @override
  Future<String> uploadSignature({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
    required int version,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final client = await _requireClient();
    final path = '$empresaId/$ratId/$assinaturaId/v$version.png';

    await client.storage
        .from(_bucket)
        .uploadBinary(path, Uint8List.fromList(bytes));

    return path;
  }

  @override
  Future<void> upsertMetadata({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
    required String storagePath,
    required String sha256,
    required int sizeBytes,
    required String mimeType,
    required int version,
    required DateTime? deletedAt,
  }) async {
    final client = await _requireClient();

    await client.from('rat_signature_attachments').upsert({
      'empresa_id': empresaId,
      'rat_id': ratId,
      'assinatura_id': assinaturaId,
      'storage_bucket': _bucket,
      'storage_path': storagePath,
      'sha256': sha256,
      'size_bytes': sizeBytes,
      'mime_type': mimeType,
      'version': version,
      'deleted_at': deletedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'empresa_id,rat_id,assinatura_id,version');
  }

  @override
  Future<String> createSignedUrl({
    required String storagePath,
    int expiresInSeconds = _expiresIn,
  }) async {
    final client = await _requireClient();

    final url = client.storage
        .from(_bucket)
        .createSignedUrl(storagePath, expiresInSeconds);

    return url;
  }

  @override
  Future<bool> objectExists(String storagePath) async {
    final client = await _requireClient();

    try {
      final data = await client.storage
          .from(_bucket)
          .download(storagePath);
      return data.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markDeleted({
    required String empresaId,
    required String ratId,
    required String assinaturaId,
  }) async {
    final client = await _requireClient();

    await client.from('rat_signature_attachments').update({
      'deleted_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).match({
      'empresa_id': empresaId,
      'rat_id': ratId,
      'assinatura_id': assinaturaId,
    });
  }

  Future<SupabaseClient> _requireClient() async {
    final client = await _clientFactory.tryCreateAuthenticatedClient();

    if (client == null) {
      throw StateError('Sessao remota nao restaurada.');
    }

    return client;
  }

  static String computeSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}