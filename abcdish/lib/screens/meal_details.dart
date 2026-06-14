import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:abcdish/l10n/app_text.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/providers/favorites_provider.dart';
import 'package:abcdish/providers/shopping_list_provider.dart';
import 'package:abcdish/screens/partner_stores.dart';
import 'package:abcdish/services/meal_service.dart';
import 'package:abcdish/services/video_access_service.dart';
import 'package:abcdish/utils/app_snack_bar.dart';
import 'package:abcdish/utils/auth_navigation.dart';

class MealDetailsScreen extends ConsumerStatefulWidget {
  const MealDetailsScreen({super.key, required this.meal});

  final Meal meal;

  @override
  ConsumerState<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends ConsumerState<MealDetailsScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  late Meal _meal;
  bool _isLoadingRecipe = false;
  String? _recipeLoadError;

  bool _isVideoReady = false;
  bool _isInitialisingVideo = false;
  bool _checkingVideoAccess = false;
  bool _videoAccessAllowed = false;
  String? _videoAccessMessage;

  @override
  void initState() {
    super.initState();
    _meal = widget.meal;
    _loadFullRecipe();
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  Future<void> _disposeVideo() async {
    final chewie = _chewieController;
    final video = _videoController;

    _chewieController = null;
    _videoController = null;
    _isVideoReady = false;

    chewie?.dispose();
    await video?.dispose();
  }

  Future<bool> _ensureVideoReady() async {
    if (_isVideoReady &&
        _chewieController != null &&
        _videoController != null) {
      return true;
    }

    if (_isInitialisingVideo) {
      return false;
    }

    final url = _meal.videoUrl.trim();
    if (url.isEmpty) {
      setState(() {
        _videoAccessMessage = ref
            .read(appTextProvider)
            .raw('Video is not available for this recipe yet.');
      });
      return false;
    }

    setState(() {
      _isInitialisingVideo = true;
      _videoAccessMessage = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return false;
      }

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        aspectRatio: controller.value.aspectRatio,
      );

      setState(() {
        _videoController = controller;
        _chewieController = chewieController;
        _isVideoReady = true;
        _isInitialisingVideo = false;
      });

      return true;
    } catch (error) {
      debugPrint('Video initialisation error: $error');
      if (!mounted) return false;

      setState(() {
        _isInitialisingVideo = false;
        _isVideoReady = false;
        _videoAccessMessage = ref
            .read(appTextProvider)
            .raw('Unable to load cooking video.');
      });
      return false;
    }
  }

  Future<void> _checkAccessAndPlay() async {
    if (_checkingVideoAccess || _isInitialisingVideo) {
      return;
    }

    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !mounted) return;

    if (!_videoAccessAllowed) {
      setState(() {
        _checkingVideoAccess = true;
        _videoAccessMessage = null;
      });

      try {
        final access = await VideoAccessService.instance.recordVideoView(
          _meal.id,
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
              ? ref.read(appTextProvider).raw('Unlimited videos enabled')
              : '${access.remainingViews} ${ref.read(appTextProvider).raw('videos remaining this month')}';
        });
      } catch (error) {
        debugPrint('Video access error: $error');
        if (!mounted) return;

        final handled = await redirectToLoginForAuthError(context, ref, error);
        if (handled || !mounted) return;

        setState(() {
          _checkingVideoAccess = false;
          _videoAccessMessage = ref
              .read(appTextProvider)
              .raw('Unable to check video access.');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${ref.read(appTextProvider).raw('Unable to check video access.')} $error',
            ),
          ),
        );
        return;
      }
    }

    final ready = await _ensureVideoReady();
    if (!ready || !mounted) return;

    await _videoController?.play();
    if (mounted) setState(() {});
  }

  Widget _buildVideoPlayer() {
    final controller = _videoController;
    final chewieController = _chewieController;

    if (_isVideoReady && controller != null && chewieController != null) {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Chewie(controller: chewieController),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_meal.imageUrl.trim().isNotEmpty)
            Image.network(
              _meal.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _videoFallback(),
            )
          else
            _videoFallback(),
          Container(color: Colors.black45),
          Center(
            child: (_checkingVideoAccess || _isInitialisingVideo)
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: _checkAccessAndPlay,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(ref.read(appTextProvider).raw('Watch & Cook')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _videoFallback() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_menu, size: 64, color: Colors.white70),
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

  Future<void> _addAllIngredients() async {
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn) {
      await ensureLoggedIn(context, ref);
      return;
    }

    ref
        .read(shoppingListProvider.notifier)
        .addIngredients(_meal.ingredients);

    ScaffoldMessenger.of(context).showSnackBar(
      successSnackBar(
        '${_meal.ingredients.length} ${ref.read(appTextProvider).raw('ingredients added for Recipe ID')} ${_meal.recipeCode}',
      ),
    );
  }

  Future<void> _loadFullRecipe() async {
    if (_meal.isContestEntry) return;

    setState(() {
      _isLoadingRecipe = true;
      _recipeLoadError = null;
    });

    try {
      final fullMeal = await MealService.instance.fetchMeal(_meal.id);
      if (!mounted) return;

      setState(() {
        _meal = fullMeal;
        _isLoadingRecipe = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingRecipe = false;
        _recipeLoadError = error.toString();
      });
    }
  }

  void _openPartnerStores() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PartnerStoresScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meal = _meal;
    final colorScheme = Theme.of(context).colorScheme;
    final text = ref.watch(appTextProvider);
    final favoriteMeals = ref.watch(favoriteMealsProvider);
    final isFavorite = favoriteMeals.any((item) => item.id == meal.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(meal.title),
        actions: [
          IconButton(
            onPressed: () async {
              final canContinue = await ensureLoggedIn(context, ref);
              if (!canContinue || !context.mounted) return;

              final wasAdded = ref
                  .read(favoriteMealsProvider.notifier)
                  .toggleMealFavoriteStatus(meal);

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                wasAdded
                    ? successSnackBar(text.raw('Recipe saved'))
                    : errorSnackBar(
                        text.raw('Recipe removed from saved recipes'),
                      ),
              );
            },
            icon: Icon(
              isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: isFavorite ? colorScheme.primary : null,
            ),
            tooltip: isFavorite ? text.saved : text.raw('Save recipe'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAllIngredients,
        icon: const Icon(Icons.shopping_cart),
        label: Text(text.raw('Add ingredients')),
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
                        icon: Icons.confirmation_number_outlined,
                        label: '${text.raw('Recipe ID')} ${meal.recipeCode}',
                      ),
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
                  const SizedBox(height: 16),
                  if (_isLoadingRecipe)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (_recipeLoadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        text.raw('Unable to load full recipe details.'),
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.storefront_outlined,
                        color: colorScheme.primary,
                      ),
                      title: Text(text.raw('Order ingredients')),
                      subtitle: Text(
                        '${text.raw('Tell a partner store')}: ${text.raw('Recipe ID')} ${meal.recipeCode}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openPartnerStores,
                    ),
                  ),
                  _buildSectionTitle(text.raw('Ingredients')),
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
                          onPressed: () async {
                            final canContinue = await ensureLoggedIn(
                              context,
                              ref,
                            );
                            if (!canContinue || !context.mounted) return;

                            ref
                                .read(shoppingListProvider.notifier)
                                .addIngredient(ingredient);

                            ScaffoldMessenger.of(context).showSnackBar(
                              successSnackBar(
                                '$ingredient ${text.raw('added to shopping list')}',
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  _buildSectionTitle(text.raw('Cooking Steps')),
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
