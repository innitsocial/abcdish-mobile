import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/category.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/categories_provider.dart';
import 'package:abcdish/screens/meal_details.dart';
import 'package:abcdish/screens/meals.dart';
import 'package:abcdish/widgets/category_grid_item.dart';
import 'package:abcdish/widgets/meal_item.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.availableMeals});

  final List<Meal> availableMeals;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _selectCategory(BuildContext context, Category category) {
    final filteredMeals = widget.availableMeals.where((meal) {
      return meal.categories.contains(category.id);
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>
            MealsScreen(title: category.title, meals: filteredMeals),
      ),
    );
  }

  void _selectMeal(BuildContext context, Meal meal) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => MealDetailsScreen(meal: meal)));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Failed to load categories: $error')),
      data: (categories) {
        final filteredCategories = _filterCategories(categories);
        final filteredMeals = _filterMeals(categories);

        final isSearching = _searchQuery.trim().isNotEmpty;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                cursorColor: Theme.of(context).colorScheme.primary,
                decoration: InputDecoration(
                  hintText: 'Search recipes, ingredients or categories...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: isSearching
                  ? _buildSearchResults(
                      context,
                      filteredCategories,
                      filteredMeals,
                    )
                  : _buildBrowseCategories(context, filteredCategories),
            ),
          ],
        );
      },
    );
  }

  List<Category> _filterCategories(List<Category> categories) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return categories;
    }

    return categories.where((category) {
      return category.title.toLowerCase().contains(query);
    }).toList();
  }

  List<Meal> _filterMeals(List<Category> categories) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    return widget.availableMeals.where((meal) {
      final titleMatch = meal.title.toLowerCase().contains(query);

      final descriptionMatch = meal.description.toLowerCase().contains(query);

      final ingredientMatch = meal.ingredients.any(
        (ingredient) => ingredient.toLowerCase().contains(query),
      );

      final categoryMatch = meal.categories.any((categoryId) {
        final matchingCategories = categories.where(
          (category) => category.id == categoryId,
        );

        if (matchingCategories.isEmpty) {
          return false;
        }

        return matchingCategories.first.title.toLowerCase().contains(query);
      });

      return titleMatch || descriptionMatch || ingredientMatch || categoryMatch;
    }).toList();
  }

  Widget _buildBrowseCategories(
    BuildContext context,
    List<Category> categories,
  ) {
    return GridView(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      children: [
        for (final category in categories)
          CategoryGridItem(
            category: category,
            onSelectCategory: () {
              _selectCategory(context, category);
            },
          ),
      ],
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    List<Category> categories,
    List<Meal> meals,
  ) {
    if (categories.isEmpty && meals.isEmpty) {
      return const Center(child: Text('No recipes or categories found.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (categories.isNotEmpty) ...[
          Text(
            'Categories',
            style: Theme.of(
              context,
            ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            children: [
              for (final category in categories)
                CategoryGridItem(
                  category: category,
                  onSelectCategory: () {
                    _selectCategory(context, category);
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (meals.isNotEmpty) ...[
          Text(
            'Recipes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final meal in meals)
            MealItem(
              meal: meal,
              onSelectMeal: (meal) {
                _selectMeal(context, meal);
              },
            ),
        ],
      ],
    );
  }
}
