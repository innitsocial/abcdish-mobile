import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:meals/providers/shopping_list_provider.dart';
import 'package:meals/models/meal.dart';
import 'package:meals/providers/favorites_provider.dart';

class MealDetailsScreen extends ConsumerStatefulWidget {
  const MealDetailsScreen({super.key, required this.meal});

  final Meal meal;

  @override
  ConsumerState<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends ConsumerState<MealDetailsScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoReady = false;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.meal.videoUrl),
    );

    _videoController
        .initialize()
        .then((_) {
          if (!mounted) return;

          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: false,
            looping: false,
            allowFullScreen: true,
            allowMuting: true,
            showControls: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: Theme.of(context).colorScheme.primary,
              handleColor: Theme.of(context).colorScheme.primary,
            ),
          );

          setState(() {
            _isVideoReady = true;
          });
        })
        .catchError((error) {
          debugPrint('Video error: $error');
          if (!mounted) return;

          setState(() {
            _isVideoReady = false;
          });
        });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    if (_videoController.value.hasError) {
      return Container(
        height: 250,
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(
          'Video failed to load.\n${_videoController.value.errorDescription ?? ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (!_isVideoReady || _chewieController == null) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _addAllIngredients() {
    ref
        .read(shoppingListProvider.notifier)
        .addIngredients(widget.meal.ingredients);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.meal.ingredients.length} ingredients added to shopping list',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final colorScheme = Theme.of(context).colorScheme;
    final favoriteMeals = ref.watch(favoriteMealsProvider);
    final isFavorite = favoriteMeals.contains(meal);

    return Scaffold(
      appBar: AppBar(
        title: Text(meal.title),
        actions: [
          IconButton(
            onPressed: () {
              final wasAdded = ref
                  .read(favoriteMealsProvider.notifier)
                  .toggleMealFavoriteStatus(meal);

              ScaffoldMessenger.of(context).clearSnackBars();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    wasAdded
                        ? 'Recipe added to favourites'
                        : 'Recipe removed from favourites',
                  ),
                ),
              );
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: Tween(begin: 0.8, end: 1.0).animate(animation),
                  child: child,
                );
              },
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isFavorite),
                color: isFavorite ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAllIngredients,
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Add ingredients'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: meal.id,
              child: Material(color: Colors.black, child: _buildVideoPlayer()),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meal.description,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        icon: Icons.schedule,
                        label: '${meal.duration} min',
                      ),
                      _buildInfoChip(
                        icon: Icons.local_fire_department,
                        label: meal.complexity.name,
                      ),
                      _buildInfoChip(
                        icon: Icons.payments,
                        label: meal.affordability.name,
                      ),
                    ],
                  ),
                  _buildSectionTitle('Ingredients'),
                  ...meal.ingredients.map(
                    (ingredient) => Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.check_circle_outline,
                          color: colorScheme.primary,
                        ),
                        title: Text(
                          ingredient,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            ref
                                .read(shoppingListProvider.notifier)
                                .addIngredient(ingredient);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$ingredient added to shopping list',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  _buildSectionTitle('Cooking Steps'),
                  ...meal.steps.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final step = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('$index')),
                        title: Text(
                          step,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
