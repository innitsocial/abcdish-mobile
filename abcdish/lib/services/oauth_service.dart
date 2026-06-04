import 'package:abcdish/models/oauth_provider_info.dart';
import 'package:abcdish/services/api_client.dart';

class OAuthService {
  OAuthService._internal();

  static final OAuthService instance = OAuthService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<OAuthProviderInfo>> fetchProviders() async {
    final response = await _apiClient.get('/api/oauth2/providers');

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(OAuthProviderInfo.fromJson)
          .toList();
    }

    return [];
  }
}
