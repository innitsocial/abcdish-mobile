import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/category.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/categories_provider.dart';
import 'package:abcdish/screens/meal_details.dart';
import 'package:abcdish/widgets/meal_horizontal_card.dart';
import 'package:abcdish/widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.availableMeals});

  final List<Meal> availableMeals;

  void _selectMeal(BuildContext context, Meal meal) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => MealDetailsScreen(meal: meal)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Failed to load categories: $error')),
      data: (categories) {
        final featuredMeal = availableMeals.first;

        return ListView(
          children: [
            _FeaturedRecipe(
              meal: featuredMeal,
              onSelectMeal: () {
                _selectMeal(context, featuredMeal);
              },
            ),
            _MealSection(
              title: 'Popular Recipes',
              subtitle: 'Start cooking something delicious today',
              meals: availableMeals,
              onSelectMeal: (meal) {
                _selectMeal(context, meal);
              },
            ),
            for (final category in categories)
              _MealSection(
                title: category.title,
                subtitle: 'Explore ${category.title} recipes',
                meals: _mealsForCategory(availableMeals, category),
                onSelectMeal: (meal) {
                  _selectMeal(context, meal);
                },
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  List<Meal> _mealsForCategory(List<Meal> meals, Category category) {
    return meals.where((meal) {
      return meal.categories.contains(category.id);
    }).toList();
  }
}

class _FeaturedRecipe extends StatelessWidget {
  const _FeaturedRecipe({required this.meal, required this.onSelectMeal});

  final Meal meal;
  final VoidCallback onSelectMeal;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelectMeal,
      child: Stack(
        children: [
          Hero(
            tag: meal.id,
            child: Image.network(
              meal.imageUrl,
              height: 320,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured Recipe',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  meal.title,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meal.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onSelectMeal,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch & Cook'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.title,
    required this.subtitle,
    required this.meals,
    required this.onSelectMeal,
  });

  final String title;
  final String subtitle;
  final List<Meal> meals;
  final void Function(Meal meal) onSelectMeal;

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        SizedBox(
          height: 170,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 4),
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];

              return MealHorizontalCard(meal: meal, onSelectMeal: onSelectMeal);
            },
          ),
        ),
      ],
    );
  }
}
