import 'package:flutter/material.dart';

import 'package:abcdish/data/dummy_data.dart';
import 'package:abcdish/models/category.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/screens/meal_details.dart';
import 'package:abcdish/screens/meals.dart';
import 'package:abcdish/widgets/category_grid_item.dart';
import 'package:abcdish/widgets/meal_item.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.availableMeals});

  final List<Meal> availableMeals;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
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

      return titleMatch || ingredientMatch || categoryMatch;
    }).toList();
  }

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0,
      upperBound: 1,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
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

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _filteredCategories;
    final filteredMeals = _filteredMeals;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search recipes, ingredients or categories...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
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
          child: AnimatedBuilder(
            animation: _animationController,
            child: _isSearching
                ? _buildSearchResults(
                    context,
                    filteredCategories,
                    filteredMeals,
                  )
                : _buildCategoryGrid(context, availableCategories),
            builder: (context, child) => SlideTransition(
              position:
                  Tween(
                    begin: const Offset(0, 0.3),
                    end: const Offset(0, 0),
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    ),
                  ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<Category> categories) {
    return GridView(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
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
          Text('Categories', style: Theme.of(context).textTheme.titleLarge),
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
          Text('Recipes', style: Theme.of(context).textTheme.titleLarge),
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
