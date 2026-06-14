import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:abcdish/providers/meals_provider.dart';

import 'package:abcdish/models/meal.dart';

enum DietaryFilter { glutenFree, lactoseFree, vegetarian, vegan }

enum DifficultyFilter { simple, challenging, hard }

class RecipeFilters {
  const RecipeFilters({
    this.glutenFree = false,
    this.lactoseFree = false,
    this.vegetarian = false,
    this.vegan = false,
    this.maxDuration,
    this.difficulty,
  });

  final bool glutenFree;
  final bool lactoseFree;
  final bool vegetarian;
  final bool vegan;
  final int? maxDuration;
  final DifficultyFilter? difficulty;

  bool get hasActiveFilters {
    return glutenFree ||
        lactoseFree ||
        vegetarian ||
        vegan ||
        maxDuration != null ||
        difficulty != null;
  }

  RecipeFilters copyWith({
    bool? glutenFree,
    bool? lactoseFree,
    bool? vegetarian,
    bool? vegan,
    int? maxDuration,
    bool clearMaxDuration = false,
    DifficultyFilter? difficulty,
    bool clearDifficulty = false,
  }) {
    return RecipeFilters(
      glutenFree: glutenFree ?? this.glutenFree,
      lactoseFree: lactoseFree ?? this.lactoseFree,
      vegetarian: vegetarian ?? this.vegetarian,
      vegan: vegan ?? this.vegan,
      maxDuration: clearMaxDuration ? null : maxDuration ?? this.maxDuration,
      difficulty: clearDifficulty ? null : difficulty ?? this.difficulty,
    );
  }
}

class FiltersNotifier extends StateNotifier<RecipeFilters> {
  FiltersNotifier() : super(const RecipeFilters());

  void toggleDietary(DietaryFilter filter) {
    switch (filter) {
      case DietaryFilter.glutenFree:
        state = state.copyWith(glutenFree: !state.glutenFree);
      case DietaryFilter.lactoseFree:
        state = state.copyWith(lactoseFree: !state.lactoseFree);
      case DietaryFilter.vegetarian:
        state = state.copyWith(vegetarian: !state.vegetarian);
      case DietaryFilter.vegan:
        state = state.copyWith(vegan: !state.vegan);
    }
  }

  void setMaxDuration(int? maxDuration) {
    state = maxDuration == null
        ? state.copyWith(clearMaxDuration: true)
        : state.copyWith(maxDuration: maxDuration);
  }

  void setDifficulty(DifficultyFilter? difficulty) {
    state = difficulty == null
        ? state.copyWith(clearDifficulty: true)
        : state.copyWith(difficulty: difficulty);
  }

  void clear() => state = const RecipeFilters();
}

final filtersProvider = StateNotifierProvider<FiltersNotifier, RecipeFilters>(
  (ref) => FiltersNotifier(),
);

final filteredMealsProvider = Provider<AsyncValue<List<Meal>>>((ref) {
  final mealsAsync = ref.watch(mealsProvider);
  final activeFilters = ref.watch(filtersProvider);

  return mealsAsync.whenData((meals) {
    return meals
        .where((meal) => mealMatchesFilters(meal, activeFilters))
        .toList();
  });
});

bool mealMatchesFilters(Meal meal, RecipeFilters filters) {
  if (filters.glutenFree && !meal.isGlutenFree) return false;
  if (filters.lactoseFree && !meal.isLactoseFree) return false;
  if (filters.vegetarian && !meal.isVegetarian) return false;
  if (filters.vegan && !meal.isVegan) return false;
  if (filters.maxDuration != null && meal.duration > filters.maxDuration!) {
    return false;
  }
  if (filters.difficulty != null &&
      meal.complexity.name != filters.difficulty!.name) {
    return false;
  }

  return true;
}
