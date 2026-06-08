import 'package:http/http.dart' as http;

enum ConnectionTestResult {
  success,
  invalidUrl,
  unreachable,
  invalidKey,
  unexpectedError,
}

class RemoteServerConnectionTester {
  Future<ConnectionTestResult> test({
    required String supabaseUrl,
    required String supabasePublicKey,
  }) async {
    final uri = Uri.tryParse(supabaseUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return ConnectionTestResult.invalidUrl;
    }

    if (supabasePublicKey.trim().isEmpty) {
      return ConnectionTestResult.invalidKey;
    }

    try {
      // Testa o endpoint /auth/v1/settings via GET público (não requer auth)
      // ou o health endpoint do Supabase
      final healthUrl = Uri.parse(
        '${uri.toString().replaceAll(RegExp(r'/$'), '')}/rest/v1/',
      );
      final response = await http
          .get(
            healthUrl,
            headers: {
              'apikey': supabasePublicKey.trim(),
              'Authorization': 'Bearer ${supabasePublicKey.trim()}',
            },
          )
          .timeout(const Duration(seconds: 10));

      // Se retornar 200-299 ou 401/403 (key válida mas sem permissão), a conexão funciona
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return ConnectionTestResult.success;
      }
      // 401/403 significa key válida mas sem acesso — conexão OK
      if (response.statusCode == 401 || response.statusCode == 403) {
        return ConnectionTestResult.success;
      }
      return ConnectionTestResult.unreachable;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('HandshakeException')) {
        return ConnectionTestResult.unreachable;
      }
      return ConnectionTestResult.unexpectedError;
    }
  }
}
