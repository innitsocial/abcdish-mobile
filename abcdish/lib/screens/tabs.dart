import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/l10n/app_text.dart';
import 'package:abcdish/providers/favorites_provider.dart';
import 'package:abcdish/providers/filters_provider.dart';
import 'package:abcdish/providers/meals_provider.dart';
import 'package:abcdish/screens/contests.dart';
import 'package:abcdish/screens/food_feed.dart';
import 'package:abcdish/screens/home.dart';
import 'package:abcdish/screens/meals.dart';
import 'package:abcdish/screens/profile.dart';
import 'package:abcdish/screens/search.dart';
import 'package:abcdish/screens/shopping_list.dart';
import 'package:abcdish/utils/error_messages.dart';
import 'package:abcdish/widgets/app_bottom_nav.dart';

class TabsScreen extends ConsumerStatefulWidget {
  const TabsScreen({super.key});

  @override
  ConsumerState<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = ref.watch(appTextProvider);

    final pages = [
      (text.feed, const FoodFeedScreen()),
      (text.recipes, const _RecipesTab()),
      (text.search, const _SearchTab()),
      (text.saved, const _SavedMealsTab()),
      (text.contests, const ContestsScreen()),
      (text.shoppingList, const ShoppingListScreen()),
      (text.profile, const ProfileScreen()),
    ];

    final activePageTitle = pages[_selectedPageIndex].$1;
    final activePage = pages[_selectedPageIndex].$2;

    return Scaffold(
      appBar: AppBar(title: Text(activePageTitle)),
      body: activePage,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedPageIndex,
        onTap: _selectPage,
      ),
    );
  }
}

class _RecipesTab extends ConsumerWidget {
  const _RecipesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealsProvider);
    final filteredMealsAsync = ref.watch(filteredMealsProvider);

    return mealsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _LoadError(
        contextLabel: 'Recipes tab failed',
        error: error,
        stackTrace: stackTrace,
        fallback: 'We could not load recipes right now. Please try again.',
        onRetry: () => ref.invalidate(mealsProvider),
      ),
      data: (availableMeals) {
        final visibleMeals = filteredMealsAsync.value ?? availableMeals;
        return HomeScreen(availableMeals: visibleMeals);
      },
    );
  }
}

class _SearchTab extends ConsumerWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealsProvider);

    return mealsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _LoadError(
        contextLabel: 'Search recipes failed',
        error: error,
        stackTrace: stackTrace,
        fallback: 'We could not load search right now. Please try again.',
        onRetry: () => ref.invalidate(mealsProvider),
      ),
      data: (availableMeals) => SearchScreen(availableMeals: availableMeals),
    );
  }
}

class _SavedMealsTab extends ConsumerWidget {
  const _SavedMealsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MealsScreen(meals: ref.watch(favoriteMealsProvider));
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.contextLabel,
    required this.error,
    required this.stackTrace,
    required this.fallback,
    required this.onRetry,
  });

  final String contextLabel;
  final Object error;
  final StackTrace stackTrace;
  final String fallback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    logUiError(contextLabel, error, stackTrace);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userFriendlyErrorMessage(error, fallback: fallback),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
