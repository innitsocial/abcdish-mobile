import 'package:flutter/material.dart';

import 'package:abcdish/data/dummy_data.dart';
import 'package:abcdish/models/category.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/screens/meal_details.dart';
import 'package:abcdish/screens/meals.dart';
import 'package:abcdish/widgets/category_grid_item.dart';
import 'package:abcdish/widgets/meal_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.availableMeals});

  final List<Meal> availableMeals;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  List<Category> get _filteredCategories {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return availableCategories;
    }

    return availableCategories.where((category) {
      return category.title.toLowerCase().contains(query);
    }).toList();
  }

  List<Meal> get _filteredMeals {
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
        final matchingCategories = availableCategories.where(
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
    final filteredCategories = _filteredCategories;
    final filteredMeals = _filteredMeals;
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search recipes, ingredients or categories...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
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
              ? _buildSearchResults(context, filteredCategories, filteredMeals)
              : _buildBrowseCategories(context, filteredCategories),
        ),
      ],
    );
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
