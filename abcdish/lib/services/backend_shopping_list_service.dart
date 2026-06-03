import 'package:abcdish/models/shopping_list_item.dart';
import 'package:abcdish/services/api_client.dart';

class BackendShoppingListService {
  BackendShoppingListService._internal();

  static final BackendShoppingListService instance =
      BackendShoppingListService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<ShoppingListItem>> fetchItems() async {
    final response = await _apiClient.get('/api/shopping-list');
    final data = response is List ? response : response['items'] ?? [];
    return (data as List)
        .map((item) => ShoppingListItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ShoppingListItem> addItem({
    required String ingredientName,
    String? quantity,
  }) async {
    final response = await _apiClient.post(
      '/api/shopping-list',
      body: {'ingredientName': ingredientName, 'quantity': quantity},
    );
    return ShoppingListItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteItem(int itemId) async {
    await _apiClient.delete('/api/shopping-list/$itemId');
  }
}
