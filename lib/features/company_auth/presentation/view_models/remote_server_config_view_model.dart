import 'package:flutter/foundation.dart';
import 'package:techreport/features/company_auth/data/services/remote_server_connection_tester.dart';
import 'package:techreport/features/company_auth/domain/entities/remote_endpoint_config.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';

enum RemoteServerConfigStatus {
  idle,
  testing,
  testSuccess,
  saving,
  saved,
  failure,
}

class RemoteServerConfigViewModel extends ChangeNotifier {
  RemoteServerConfigViewModel({
    required RemoteEndpointRepository remoteEndpointRepository,
    RemoteServerConnectionTester? connectionTester,
  }) : _remoteEndpointRepository = remoteEndpointRepository,
       _connectionTester = connectionTester ?? RemoteServerConnectionTester();

  final RemoteEndpointRepository _remoteEndpointRepository;
  final RemoteServerConnectionTester _connectionTester;

  RemoteServerConfigStatus status = RemoteServerConfigStatus.idle;
  String? errorMessage;

  bool get isSaving => status == RemoteServerConfigStatus.saving;
  bool get isSaved => status == RemoteServerConfigStatus.saved;
  bool get isTesting => status == RemoteServerConfigStatus.testing;
  bool get isTestSuccess => status == RemoteServerConfigStatus.testSuccess;
  bool get hasError => errorMessage != null;

  void invalidateTest() {
    if (status == RemoteServerConfigStatus.testSuccess) {
      status = RemoteServerConfigStatus.idle;
      notifyListeners();
    }
  }

  Future<ConnectionTestResult> testConnection({
    required String supabaseUrl,
    required String supabasePublicKey,
  }) async {
    status = RemoteServerConfigStatus.testing;
    errorMessage = null;
    notifyListeners();

    final result = await _connectionTester.test(
      supabaseUrl: supabaseUrl,
      supabasePublicKey: supabasePublicKey,
    );

    switch (result) {
      case ConnectionTestResult.success:
        status = RemoteServerConfigStatus.testSuccess;
        errorMessage = null;
      case ConnectionTestResult.invalidUrl:
        status = RemoteServerConfigStatus.failure;
        errorMessage = 'URL inválida. Verifique o endereço.';
      case ConnectionTestResult.invalidKey:
        status = RemoteServerConfigStatus.failure;
        errorMessage = 'Chave pública vazia.';
      case ConnectionTestResult.unreachable:
        status = RemoteServerConfigStatus.failure;
        errorMessage = 'Servidor inacessível. Verifique a URL e sua conexão.';
      case ConnectionTestResult.unexpectedError:
        status = RemoteServerConfigStatus.failure;
        errorMessage = 'Erro inesperado ao testar conexão.';
    }

    notifyListeners();
    return result;
  }

  Future<bool> save({
    required String nome,
    required String supabaseUrl,
    required String supabasePublicKey,
  }) async {
    if (status != RemoteServerConfigStatus.testSuccess) {
      status = RemoteServerConfigStatus.failure;
      errorMessage = 'Teste a conexão antes de salvar.';
      notifyListeners();
      return false;
    }

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

      status = RemoteServerConfigStatus.idle;
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
