import 'package:flutter/material.dart';

import 'package:meals/data/dummy_data.dart';
import 'package:meals/models/meal.dart';
import 'package:meals/screens/meal_details.dart';
import 'package:meals/widgets/meal_horizontal_card.dart';
import 'package:meals/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.availableMeals});

  final List<Meal> availableMeals;

  void _selectMeal(BuildContext context, Meal meal) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => MealDetailsScreen(meal: meal)));
  }

  List<Meal> _mealsForCategory(String categoryId) {
    return availableMeals.where((meal) {
      return meal.categories.contains(categoryId);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final featuredMeal = availableMeals.isNotEmpty
        ? availableMeals.first
        : dummyMeals.first;

    final indianMeals = _mealsForCategory('c1');
    final quickMeals = _mealsForCategory('c3');
    final breakfastMeals = _mealsForCategory('c4');
    final healthyMeals = _mealsForCategory('c5');

    return ListView(
      children: [
        _FeaturedRecipe(
          meal: featuredMeal,
          onSelectMeal: () => _selectMeal(context, featuredMeal),
        ),
        _MealSection(
          title: 'Popular Recipes',
          subtitle: 'Start cooking something delicious today',
          meals: availableMeals,
          onSelectMeal: (meal) => _selectMeal(context, meal),
        ),
        _MealSection(
          title: 'Indian Favourites',
          subtitle: 'Comfort food with bold flavours',
          meals: indianMeals,
          onSelectMeal: (meal) => _selectMeal(context, meal),
        ),
        _MealSection(
          title: 'Quick & Easy',
          subtitle: 'Fast meals for busy days',
          meals: quickMeals,
          onSelectMeal: (meal) => _selectMeal(context, meal),
        ),
        _MealSection(
          title: 'Healthy Picks',
          subtitle: 'Fresh, balanced and lighter recipes',
          meals: healthyMeals,
          onSelectMeal: (meal) => _selectMeal(context, meal),
        ),
        _MealSection(
          title: 'Breakfast Ideas',
          subtitle: 'Start your day with something tasty',
          meals: breakfastMeals,
          onSelectMeal: (meal) => _selectMeal(context, meal),
        ),
        const SizedBox(height: 24),
      ],
    );
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
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 320,
                  alignment: Alignment.center,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image),
                );
              },
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
