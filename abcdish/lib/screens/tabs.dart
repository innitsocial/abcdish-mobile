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
    final mealsAsync = ref.watch(mealsProvider);
    final filteredMealsAsync = ref.watch(filteredMealsProvider);
    final text = ref.watch(appTextProvider);

    return mealsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load recipes. Please check the backend.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (availableMeals) {
        final visibleMeals = filteredMealsAsync.value ?? availableMeals;
        final pages = [
          (text.feed, const FoodFeedScreen()),
          (text.recipes, HomeScreen(availableMeals: visibleMeals)),
          (text.search, SearchScreen(availableMeals: availableMeals)),
          (text.saved, MealsScreen(meals: ref.watch(favoriteMealsProvider))),
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
      },
    );
  }
}
