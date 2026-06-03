import 'package:abcdish/models/oauth_provider.dart';
import 'package:abcdish/services/api_client.dart';

class OAuthService {
  OAuthService._internal();

  static final OAuthService instance = OAuthService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<OAuthProviderOption>> fetchProviders() async {
    final response = await _apiClient.get('/api/oauth2/providers');
    final data = response is List
        ? response
        : response['providers'] ?? response['items'] ?? [];
    return (data as List)
        .map(
          (item) => OAuthProviderOption.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<OAuthProviderOption> startProvider(String provider) async {
    final response = await _apiClient.get(
      '/api/oauth2/${provider.toLowerCase()}/start',
    );
    return OAuthProviderOption.fromJson(response as Map<String, dynamic>);
  }
}
