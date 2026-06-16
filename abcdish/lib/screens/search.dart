import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/category.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/l10n/app_text.dart';
import 'package:abcdish/providers/categories_provider.dart';
import 'package:abcdish/providers/filters_provider.dart';
import 'package:abcdish/screens/meal_details.dart';
import 'package:abcdish/screens/meals.dart';
import 'package:abcdish/utils/error_messages.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _selectCategory(BuildContext context, Category category) {
    final filters = ref.read(filtersProvider);
    final filteredMeals = widget.availableMeals
        .where((meal) {
          return meal.categories.contains(category.id);
        })
        .where((meal) {
          return mealMatchesFilters(meal, filters);
        })
        .toList();

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
    final filters = ref.watch(filtersProvider);
    final text = ref.watch(appTextProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        logUiError('Search categories failed', error, stackTrace);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              userFriendlyErrorMessage(
                error,
                fallback:
                    '${text.raw('Failed to load categories')}. ${text.raw('Please try again.')}',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      data: (categories) {
        final filteredCategories = _filterCategories(categories, filters);
        final filteredMeals = _filterMeals(categories, filters);

        final hasQuery = _searchQuery.trim().isNotEmpty;
        final isSearching = hasQuery || filters.hasActiveFilters;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: Column(
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
                    hintText: text.raw(
                      'Search recipes, ingredients or categories...',
                    ),
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
                  onTapOutside: (_) => _dismissKeyboard(),
                  onSubmitted: (_) => _dismissKeyboard(),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              _FilterBar(filters: filters),
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
          ),
        );
      },
    );
  }

  List<Category> _filterCategories(
    List<Category> categories,
    RecipeFilters filters,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    return categories.where((category) {
      if (query.isNotEmpty && !category.title.toLowerCase().contains(query)) {
        return false;
      }

      if (!filters.hasActiveFilters) return true;

      return widget.availableMeals.any((meal) {
        return meal.categories.contains(category.id) &&
            mealMatchesFilters(meal, filters);
      });
    }).toList();
  }

  List<Meal> _filterMeals(List<Category> categories, RecipeFilters filters) {
    final query = _searchQuery.trim().toLowerCase();

    return widget.availableMeals.where((meal) {
      if (!mealMatchesFilters(meal, filters)) return false;

      if (query.isEmpty) return filters.hasActiveFilters;

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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
      final text = ref.read(appTextProvider);
      return Center(child: Text(text.raw('No recipes or categories found.')));
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      children: [
        if (categories.isNotEmpty) ...[
          Text(
            ref.read(appTextProvider).raw('Categories'),
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
            ref.read(appTextProvider).recipes,
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

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filters});

  final RecipeFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(filtersProvider.notifier);
    final text = ref.watch(appTextProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          FilterChip(
            selected: filters.glutenFree,
            label: Text(text.raw('Gluten-free')),
            avatar: const Icon(Icons.grass_outlined, size: 18),
            onSelected: (_) => notifier.toggleDietary(DietaryFilter.glutenFree),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: filters.lactoseFree,
            label: Text(text.raw('Lactose-free')),
            avatar: const Icon(Icons.local_drink_outlined, size: 18),
            onSelected: (_) =>
                notifier.toggleDietary(DietaryFilter.lactoseFree),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: filters.vegetarian,
            label: Text(text.raw('Vegetarian')),
            avatar: const Icon(Icons.eco_outlined, size: 18),
            onSelected: (_) => notifier.toggleDietary(DietaryFilter.vegetarian),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: filters.vegan,
            label: Text(text.raw('Vegan')),
            avatar: const Icon(Icons.spa_outlined, size: 18),
            onSelected: (_) => notifier.toggleDietary(DietaryFilter.vegan),
          ),
          const SizedBox(width: 8),
          _TimeFilterChip(
            label: text.raw('Under 15'),
            minutes: 15,
            filters: filters,
          ),
          const SizedBox(width: 8),
          _TimeFilterChip(
            label: text.raw('Under 30'),
            minutes: 30,
            filters: filters,
          ),
          const SizedBox(width: 8),
          _TimeFilterChip(
            label: text.raw('Under 60'),
            minutes: 60,
            filters: filters,
          ),
          const SizedBox(width: 8),
          _DifficultyFilterChip(
            label: text.raw('Simple'),
            difficulty: DifficultyFilter.simple,
            filters: filters,
          ),
          const SizedBox(width: 8),
          _DifficultyFilterChip(
            label: text.raw('Medium'),
            difficulty: DifficultyFilter.challenging,
            filters: filters,
          ),
          const SizedBox(width: 8),
          _DifficultyFilterChip(
            label: text.raw('Difficult'),
            difficulty: DifficultyFilter.hard,
            filters: filters,
          ),
          if (filters.hasActiveFilters) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.close, size: 18),
              label: Text(text.raw('Clear')),
              onPressed: notifier.clear,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeFilterChip extends ConsumerWidget {
  const _TimeFilterChip({
    required this.label,
    required this.minutes,
    required this.filters,
  });

  final String label;
  final int minutes;
  final RecipeFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = filters.maxDuration == minutes;

    return FilterChip(
      selected: selected,
      label: Text(label),
      avatar: const Icon(Icons.timer_outlined, size: 18),
      onSelected: (_) {
        ref
            .read(filtersProvider.notifier)
            .setMaxDuration(selected ? null : minutes);
      },
    );
  }
}

class _DifficultyFilterChip extends ConsumerWidget {
  const _DifficultyFilterChip({
    required this.label,
    required this.difficulty,
    required this.filters,
  });

  final String label;
  final DifficultyFilter difficulty;
  final RecipeFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = filters.difficulty == difficulty;

    return FilterChip(
      selected: selected,
      label: Text(label),
      avatar: const Icon(Icons.local_fire_department_outlined, size: 18),
      onSelected: (_) {
        ref
            .read(filtersProvider.notifier)
            .setDifficulty(selected ? null : difficulty);
      },
    );
  }
}
