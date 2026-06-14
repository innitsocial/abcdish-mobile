import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/meals_provider.dart';
import 'package:abcdish/screens/creator_upload.dart';
import 'package:abcdish/services/meal_service.dart';
import 'package:abcdish/utils/youtube_video.dart';

class CreatorRecipesScreen extends ConsumerWidget {
  const CreatorRecipesScreen({super.key});

  Future<void> _editRecipe(
    BuildContext context,
    WidgetRef ref,
    Meal meal,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (ctx) => CreatorUploadScreen(meal: meal)),
    );

    if (updated == true) {
      ref.invalidate(mealsProvider);
      ref.invalidate(managedMealsProvider);
    }
  }

  Future<void> _deleteRecipe(
    BuildContext context,
    WidgetRef ref,
    Meal meal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove recipe?'),
        content: Text(
          'This removes "${meal.title}" from ABCDish. The YouTube video itself will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await MealService.instance.deleteMeal(meal.id);
      ref.invalidate(mealsProvider);
      ref.invalidate(managedMealsProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${meal.title}" removed')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to remove recipe: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(managedMealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Recipes')),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load published recipes.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (meals) => _CreatorRecipeList(
          meals: meals,
          onAddRecipe: () => _addRecipe(context, ref),
          onEditRecipe: (meal) => _editRecipe(context, ref, meal),
          onDeleteRecipe: (meal) => _deleteRecipe(context, ref, meal),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addRecipe(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
      ),
    );
  }

  Future<void> _addRecipe(BuildContext context, WidgetRef ref) async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (ctx) => const CreatorUploadScreen()),
    );
    if (published == true) {
      ref.invalidate(mealsProvider);
      ref.invalidate(managedMealsProvider);
    }
  }
}

class _CreatorRecipeList extends StatelessWidget {
  const _CreatorRecipeList({
    required this.meals,
    required this.onAddRecipe,
    required this.onEditRecipe,
    required this.onDeleteRecipe,
  });

  final List<Meal> meals;
  final Future<void> Function() onAddRecipe;
  final void Function(Meal meal) onEditRecipe;
  final void Function(Meal meal) onDeleteRecipe;

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_library_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                'No recipes published yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAddRecipe,
                icon: const Icon(Icons.add),
                label: const Text('Add Recipe'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: meals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final meal = meals[index];
        final youtubeVideoId = extractYouTubeVideoId(meal.videoUrl);
        final thumbnailUrl = meal.imageUrl.trim().isNotEmpty
            ? meal.imageUrl.trim()
            : youtubeVideoId == null
            ? ''
            : youtubeThumbnailUrl(youtubeVideoId);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: thumbnailUrl.isEmpty
                    ? Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.restaurant_menu, size: 48),
                      )
                    : Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white70,
                            size: 48,
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Text(
                  meal.title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '${meal.duration} min • ${meal.complexity.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: _ModerationChip(meal: meal),
              ),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => onEditRecipe(meal),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => onDeleteRecipe(meal),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    label: Text(
                      'Remove',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModerationChip extends StatelessWidget {
  const _ModerationChip({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final status = meal.moderationStatus;
    final colorScheme = Theme.of(context).colorScheme;
    final isApproved = status == 'APPROVED';
    final isRejected = status == 'REJECTED';

    return Tooltip(
      message: meal.moderationReason.isEmpty
          ? 'Moderation status'
          : meal.moderationReason,
      child: Chip(
        avatar: Icon(
          isApproved
              ? Icons.check_circle_outline
              : isRejected
              ? Icons.cancel_outlined
              : Icons.pending_outlined,
          size: 18,
        ),
        label: Text(
          isApproved
              ? 'Published'
              : isRejected
              ? 'Rejected'
              : 'Pending review',
        ),
        backgroundColor: isApproved
            ? colorScheme.primaryContainer
            : isRejected
            ? colorScheme.errorContainer
            : colorScheme.secondaryContainer,
      ),
    );
  }
}
