import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/favorites_provider.dart';
import 'package:abcdish/providers/filters_provider.dart';
import 'package:abcdish/providers/meals_provider.dart';
import 'package:abcdish/screens/contests.dart';
import 'package:abcdish/screens/filters.dart';
import 'package:abcdish/screens/food_feed.dart';
import 'package:abcdish/screens/home.dart';
import 'package:abcdish/screens/meals.dart';
import 'package:abcdish/screens/profile.dart';
import 'package:abcdish/screens/search.dart';
import 'package:abcdish/screens/shopping_list.dart';
import 'package:abcdish/widgets/app_bottom_nav.dart';
import 'package:abcdish/widgets/main_drawer.dart';

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

  void _setScreen(String identifier) async {
    Navigator.of(context).pop();

    if (identifier == 'filters') {
      await Navigator.of(context).push<Map<Filter, bool>>(
        MaterialPageRoute(builder: (ctx) => const FiltersScreen()),
      );
    }

    if (identifier == 'favourites') {
      setState(() {
        _selectedPageIndex = 3;
      });
    }

    if (identifier == 'feed') {
      setState(() {
        _selectedPageIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(mealsProvider);

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
        Widget activePage = const FoodFeedScreen();
        var activePageTitle = 'Food Feed';

        if (_selectedPageIndex == 1) {
          activePage = HomeScreen(availableMeals: availableMeals);
          activePageTitle = 'Recipes';
        }

        if (_selectedPageIndex == 2) {
          activePage = SearchScreen(availableMeals: availableMeals);
          activePageTitle = 'Search';
        }

        if (_selectedPageIndex == 3) {
          final favoriteMeals = ref.watch(favoriteMealsProvider);
          activePage = MealsScreen(meals: favoriteMeals);
          activePageTitle = 'Favourites';
        }

        if (_selectedPageIndex == 4) {
          activePage = const ContestsScreen();
          activePageTitle = 'Contests';
        }

        if (_selectedPageIndex == 5) {
          activePage = const ShoppingListScreen();
          activePageTitle = 'Shopping List';
        }

        if (_selectedPageIndex == 6) {
          activePage = const ProfileScreen();
          activePageTitle = 'Profile';
        }

        return Scaffold(
          appBar: AppBar(title: Text(activePageTitle)),
          drawer: MainDrawer(onSelectScreen: _setScreen),
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
