import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/favorites_provider.dart';
import 'package:abcdish/providers/feed_provider.dart';
import 'package:abcdish/screens/meal_details.dart';

class FoodFeedScreen extends ConsumerWidget {
  const FoodFeedScreen({super.key});

  void _openMeal(BuildContext context, Meal meal) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => MealDetailsScreen(meal: meal)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _FeedMessage(
        title: 'Unable to load feed',
        message: '$error',
        onRetry: () => ref.invalidate(feedProvider),
      ),
      data: (meals) {
        if (meals.isEmpty) {
          return _FeedMessage(
            title: 'Food feed is warming up',
            message: 'Recipes and creator videos will appear here.',
            onRetry: () => ref.invalidate(feedProvider),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];
            return _FoodFeedCard(
              meal: meal,
              onOpenMeal: () => _openMeal(context, meal),
            );
          },
        );
      },
    );
  }
}

class _FoodFeedCard extends ConsumerWidget {
  const _FoodFeedCard({required this.meal, required this.onOpenMeal});

  final Meal meal;
  final VoidCallback onOpenMeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteMeals = ref.watch(favoriteMealsProvider);
    final isFavorite = favoriteMeals.any((item) => item.id == meal.id);
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (meal.imageUrl.trim().isNotEmpty)
          Image.network(
            meal.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          )
        else
          _fallback(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.85),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 84,
          bottom: 36,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onOpenMeal,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Watch & Cook'),
              ),
            ],
          ),
        ),
        Positioned(
          right: 14,
          bottom: 80,
          child: Column(
            children: [
              _FeedAction(
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                label: 'Save',
                color: isFavorite ? Colors.redAccent : Colors.white,
                onTap: () {
                  ref
                      .read(favoriteMealsProvider.notifier)
                      .toggleMealFavoriteStatus(meal);
                },
              ),
              const SizedBox(height: 18),
              _FeedAction(
                icon: Icons.shopping_cart_outlined,
                label: 'List',
                color: Colors.white,
                onTap: () {
                  onOpenMeal();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Open recipe to add ingredients.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _FeedAction(
                icon: Icons.restaurant_menu,
                label: '${meal.duration}m',
                color: colorScheme.primary,
                onTap: onOpenMeal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_menu, color: Colors.white70, size: 90),
    );
  }
}

class _FeedAction extends StatelessWidget {
  const _FeedAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dynamic_feed, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(
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
