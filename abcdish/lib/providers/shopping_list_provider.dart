import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListNotifier extends StateNotifier<List<String>> {
  ShoppingListNotifier() : super([]) {
    _loadShoppingList();
  }

  static const String _storageKey = 'shopping_list_items';

  Future<void> _loadShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getStringList(_storageKey);

    if (savedItems != null) {
      state = savedItems;
    }
  }

  Future<void> _saveShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state);
  }

  void addIngredient(String ingredient) {
    final cleanedIngredient = ingredient.trim();

    if (cleanedIngredient.isEmpty) return;
    if (state.contains(cleanedIngredient)) return;

    state = [...state, cleanedIngredient];
    _saveShoppingList();
  }

  void addIngredients(List<String> ingredients) {
    final updatedList = [...state];

    for (final ingredient in ingredients) {
      final cleanedIngredient = ingredient.trim();

      if (cleanedIngredient.isEmpty) continue;

      if (!updatedList.contains(cleanedIngredient)) {
        updatedList.add(cleanedIngredient);
      }
    }

    state = updatedList;
    _saveShoppingList();
  }

  void removeIngredient(String ingredient) {
    state = state.where((item) => item != ingredient).toList();
    _saveShoppingList();
  }

  void clearList() {
    state = [];
    _saveShoppingList();
  }
}

final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<String>>(
      (ref) => ShoppingListNotifier(),
    );
