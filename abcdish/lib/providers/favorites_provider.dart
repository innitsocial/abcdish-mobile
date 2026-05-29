import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/meals_provider.dart';

class FavoriteMealsNotifier extends StateNotifier<List<Meal>> {
  FavoriteMealsNotifier(this.ref) : super([]) {
    _loadFavorites();
  }

  final Ref ref;

  static const String _storageKey = 'favorite_meal_ids';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMealIds = prefs.getStringList(_storageKey) ?? [];

    final mealsAsync = ref.read(mealsProvider);

    mealsAsync.whenData((meals) {
      state = meals.where((meal) {
        return savedMealIds.contains(meal.id);
      }).toList();
    });
  }

  Future<void> refreshFavoritesFromMeals(List<Meal> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final savedMealIds = prefs.getStringList(_storageKey) ?? [];

    state = meals.where((meal) {
      return savedMealIds.contains(meal.id);
    }).toList();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteMealIds = state.map((meal) => meal.id).toList();

    await prefs.setStringList(_storageKey, favoriteMealIds);
  }

  bool toggleMealFavoriteStatus(Meal meal) {
    final mealIsFavorite = state.any((m) => m.id == meal.id);

    if (mealIsFavorite) {
      state = state.where((m) => m.id != meal.id).toList();
      _saveFavorites();
      return false;
    }

    state = [...state, meal];
    _saveFavorites();
    return true;
  }
}

final favoriteMealsProvider =
    StateNotifierProvider<FavoriteMealsNotifier, List<Meal>>(
      (ref) => FavoriteMealsNotifier(ref),
    );
