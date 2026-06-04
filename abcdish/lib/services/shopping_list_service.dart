import 'package:abcdish/models/shopping_list_item.dart';
import 'package:abcdish/services/api_client.dart';

class ShoppingListService {
  ShoppingListService._internal();

  static final ShoppingListService instance = ShoppingListService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<ShoppingListItem>> fetchItems() async {
    final response = await _apiClient.get('/api/shopping-list');

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(ShoppingListItem.fromJson)
          .toList();
    }

    return [];
  }

  Future<void> addItem(String ingredientName, {String? quantity}) async {
    await _apiClient.post(
      '/api/shopping-list',
      body: {'ingredientName': ingredientName, 'quantity': quantity},
    );
  }

  Future<void> deleteItem(int itemId) async {
    await _apiClient.delete('/api/shopping-list/$itemId');
  }
}
