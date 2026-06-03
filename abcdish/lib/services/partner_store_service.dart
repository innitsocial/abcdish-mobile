import 'package:abcdish/models/partner_store.dart';
import 'package:abcdish/services/api_client.dart';

class PartnerStoreService {
  PartnerStoreService._internal();

  static final PartnerStoreService instance = PartnerStoreService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<PartnerStore>> fetchStores() async {
    final response = await _apiClient.get('/api/partners/stores');
    final data = response is List
        ? response
        : response['items'] ?? response['stores'] ?? [];
    return (data as List)
        .map((item) => PartnerStore.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PartnerStore>> fetchCheckoutOptions() async {
    final response = await _apiClient.post(
      '/api/shopping-list/checkout-options',
    );
    final data = response is List
        ? response
        : response['stores'] ?? response['items'] ?? [];
    return (data as List)
        .map((item) => PartnerStore.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
