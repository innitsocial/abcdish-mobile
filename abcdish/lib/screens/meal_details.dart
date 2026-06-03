import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/favorites_provider.dart';
import 'package:abcdish/providers/shopping_list_provider.dart';
import 'package:abcdish/services/video_access_service.dart';

class MealDetailsScreen extends ConsumerStatefulWidget {
  const MealDetailsScreen({super.key, required this.meal});

  final Meal meal;

  @override
  ConsumerState<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends ConsumerState<MealDetailsScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  bool _isVideoReady = false;
  bool _checkingVideoAccess = false;
  bool _videoAccessAllowed = false;
  String? _videoAccessMessage;

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

  Future<void> _checkAccessAndPlay() async {
    if (_videoAccessAllowed) {
      await _videoController.play();
      setState(() {});
      return;
    }

    setState(() {
      _checkingVideoAccess = true;
      _videoAccessMessage = null;
    });

    try {
      final access = await VideoAccessService.instance.recordVideoView(
        widget.meal.id,
      );

      if (!mounted) return;

      if (!access.allowed) {
        setState(() {
          _checkingVideoAccess = false;
          _videoAccessMessage = access.message;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(access.message)));
        return;
      }

      setState(() {
        _videoAccessAllowed = true;
        _checkingVideoAccess = false;
        _videoAccessMessage = access.membershipStatus == 'ACTIVE'
            ? 'Unlimited videos enabled'
            : '${access.remainingViews} videos remaining this month';
      });

      await _videoController.play();
      setState(() {});
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _checkingVideoAccess = false;
        _videoAccessMessage = 'Please login to watch this video';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to watch this video')),
      );
    }
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

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: _videoAccessAllowed
              ? Chewie(controller: _chewieController!)
              : VideoPlayer(_videoController),
        ),
        if (!_videoAccessAllowed)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: Center(
                child: _checkingVideoAccess
                    ? const CircularProgressIndicator()
                    : FilledButton.icon(
                        onPressed: _checkAccessAndPlay,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Watch & Cook'),
                      ),
              ),
            ),
          ),
      ],
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
    final isFavorite = favoriteMeals.any((item) => item.id == meal.id);

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
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
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
            Material(color: Colors.black, child: _buildVideoPlayer()),
            if (_videoAccessMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  _videoAccessMessage!,
                  style: TextStyle(color: colorScheme.primary),
                ),
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
