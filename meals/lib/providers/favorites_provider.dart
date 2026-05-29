import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meals/data/dummy_data.dart';
import 'package:meals/models/meal.dart';

class FavoriteMealsNotifier extends StateNotifier<List<Meal>> {
  FavoriteMealsNotifier() : super([]) {
    _loadFavorites();
  }

  static const String _storageKey = 'favorite_meal_ids';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMealIds = prefs.getStringList(_storageKey) ?? [];

    final favoriteMeals = dummyMeals.where((meal) {
      return savedMealIds.contains(meal.id);
    }).toList();

    state = favoriteMeals;
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteMealIds = state.map((meal) => meal.id).toList();

    await prefs.setStringList(_storageKey, favoriteMealIds);
  }

  bool toggleMealFavoriteStatus(Meal meal) {
    final mealIsFavorite = state.contains(meal);

    if (mealIsFavorite) {
      state = state.where((m) => m.id != meal.id).toList();
      _saveFavorites();
      return false;
    } else {
      state = [...state, meal];
      _saveFavorites();
      return true;
    }
  }
}

final favoriteMealsProvider =
    StateNotifierProvider<FavoriteMealsNotifier, List<Meal>>(
      (ref) => FavoriteMealsNotifier(),
    );
