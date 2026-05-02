import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_endpoint_repository.dart';

class SupabaseClientFactory {
  SupabaseClientFactory({required RemoteEndpointRepository endpointRepository})
    : _endpointRepository = endpointRepository;

  final RemoteEndpointRepository _endpointRepository;

  Future<SupabaseClient?> tryCreateClient() async {
    final endpoint = await _endpointRepository.getActiveEndpoint();
    if (endpoint == null || !endpoint.isActive) {
      return null;
    }

    final publicKey = await _endpointRepository.readSupabasePublicKey(endpoint);

    if (publicKey == null || publicKey.trim().isEmpty) {
      return null;
    }

    return SupabaseClient(endpoint.supabaseUrl, publicKey);
  }
}
