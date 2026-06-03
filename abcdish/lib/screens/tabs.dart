import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/favorites_provider.dart';
import 'package:abcdish/providers/filters_provider.dart';
import 'package:abcdish/providers/meals_provider.dart';
import 'package:abcdish/screens/contests.dart';
import 'package:abcdish/screens/filters.dart';
import 'package:abcdish/screens/food_feed.dart';
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
              'Failed to load recipes. Please check backend is running.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (availableMeals) {
        final page = _pageForIndex(availableMeals);
        final title = _titleForIndex();
        final isWide = MediaQuery.sizeOf(context).width >= 900;

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          drawer: MainDrawer(onSelectScreen: _setScreen),
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedPageIndex,
                      onDestinationSelected: _selectPage,
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dynamic_feed_outlined),
                          selectedIcon: Icon(Icons.dynamic_feed),
                          label: Text('Feed'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.search_outlined),
                          selectedIcon: Icon(Icons.search),
                          label: Text('Search'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.favorite_border),
                          selectedIcon: Icon(Icons.favorite),
                          label: Text('Saved'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.shopping_cart_outlined),
                          selectedIcon: Icon(Icons.shopping_cart),
                          label: Text('Shopping'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.emoji_events_outlined),
                          selectedIcon: Icon(Icons.emoji_events),
                          label: Text('Contests'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: Text('Profile'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: page),
                  ],
                )
              : page,
          bottomNavigationBar: isWide
              ? null
              : AppBottomNav(
                  currentIndex: _selectedPageIndex,
                  onTap: _selectPage,
                ),
        );
      },
    );
  }

  Widget _pageForIndex(List<Meal> availableMeals) {
    if (_selectedPageIndex == 1) {
      return SearchScreen(availableMeals: availableMeals);
    }

    if (_selectedPageIndex == 2) {
      final favoriteMeals = ref.watch(favoriteMealsProvider);
      return MealsScreen(meals: favoriteMeals);
    }

    if (_selectedPageIndex == 3) {
      return const ShoppingListScreen();
    }

    if (_selectedPageIndex == 4) {
      return const ContestsScreen();
    }

    if (_selectedPageIndex == 5) {
      return const ProfileScreen();
    }

    return const FoodFeedScreen();
  }

  String _titleForIndex() {
    switch (_selectedPageIndex) {
      case 1:
        return 'Search';
      case 2:
        return 'Saved Recipes';
      case 3:
        return 'Shopping List';
      case 4:
        return 'Cooking Contests';
      case 5:
        return 'Profile';
      default:
        return 'ABCDish Feed';
    }
  }
}
