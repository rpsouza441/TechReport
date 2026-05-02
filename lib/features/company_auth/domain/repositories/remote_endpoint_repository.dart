import 'package:techreport/features/company_auth/domain/entities/remote_endpoint_config.dart';

abstract class RemoteEndpointRepository {
  Future<RemoteEndpointConfig?> getActiveEndpoint();

  Future<String?> readSupabasePublicKey(RemoteEndpointConfig endpoint);

  Future<void> saveActiveEndpoint({
    required RemoteEndpointConfig endpoint,
    required String supabasePublicKey,
  });

  Future<void> clearActiveEndpoint();
}
