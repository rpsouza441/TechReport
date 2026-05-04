import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/domain/entities/remote_endpoint_config.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';

enum RemoteServerConfigStatus { idle, saving, saved, failure }

class RemoteServerConfigViewModel extends ChangeNotifier {
  RemoteServerConfigViewModel({
    required RemoteEndpointRepository remoteEndpointRepository,
  }) : _remoteEndpointRepository = remoteEndpointRepository;

  final RemoteEndpointRepository _remoteEndpointRepository;

  RemoteServerConfigStatus status = RemoteServerConfigStatus.idle;
  String? errorMessage;

  bool get isSaving => status == RemoteServerConfigStatus.saving;
  bool get isSaved => status == RemoteServerConfigStatus.saved;
  bool get hasError => errorMessage != null;

  Future<bool> save({
    required String nome,
    required String supabaseUrl,
    required String supabasePublicKey,
  }) async {
    status = RemoteServerConfigStatus.saving;
    errorMessage = null;
    notifyListeners();

    final now = DateTime.now();

    final endpoint = RemoteEndpointConfig(
      id: 'active',
      nome: nome.trim().isEmpty ? 'Servidor TechReport' : nome.trim(),
      supabaseUrl: supabaseUrl.trim(),
      supabasePublicKeyRef: 'company_auth.supabase_public_key',
      tipo: RemoteEnvironment.supabase.name,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _remoteEndpointRepository.saveActiveEndpoint(
        endpoint: endpoint,
        supabasePublicKey: supabasePublicKey.trim(),
      );

      status = RemoteServerConfigStatus.saved;
      notifyListeners();
      return true;
    } catch (e) {
      status = RemoteServerConfigStatus.failure;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
