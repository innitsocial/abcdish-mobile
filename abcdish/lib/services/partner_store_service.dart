import 'package:abcdish/models/partner_store.dart';
import 'package:abcdish/services/api_client.dart';

class PartnerStoreService {
  PartnerStoreService._internal();

  static final PartnerStoreService instance = PartnerStoreService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<PartnerStore>> fetchStores() async {
    final response = await _apiClient.get('/api/partners/stores');

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(PartnerStore.fromJson)
          .toList();
    }

    return [];
  }

  Future<List<PartnerStore>> fetchCheckoutOptions() async {
    final response = await _apiClient.post(
      '/api/shopping-list/checkout-options',
    );

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(PartnerStore.fromJson)
          .toList();
    }

    if (response is Map<String, dynamic> && response['stores'] is List) {
      return (response['stores'] as List)
          .whereType<Map<String, dynamic>>()
          .map(PartnerStore.fromJson)
          .toList();
    }

    return [];
  }
}
