import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/language_provider.dart';
import 'package:abcdish/services/meal_service.dart';

final mealsProvider = FutureProvider<List<Meal>>((ref) async {
  ref.watch(languageProvider);
  return MealService.instance.fetchMeals();
});

final managedMealsProvider = FutureProvider<List<Meal>>((ref) async {
  ref.watch(languageProvider);
  return MealService.instance.fetchManagedMeals().timeout(
    const Duration(seconds: 12),
  );
});
