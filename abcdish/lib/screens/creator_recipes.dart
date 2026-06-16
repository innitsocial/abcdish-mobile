import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/l10n/app_text.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/meals_provider.dart';
import 'package:abcdish/screens/creator_upload.dart';
import 'package:abcdish/services/meal_service.dart';
import 'package:abcdish/utils/auth_navigation.dart';
import 'package:abcdish/utils/error_messages.dart';

class CreatorRecipesScreen extends ConsumerWidget {
  const CreatorRecipesScreen({super.key});

  Future<void> _editRecipe(
    BuildContext context,
    WidgetRef ref,
    Meal meal,
  ) async {
    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !context.mounted) return;

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
    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.read(appTextProvider).raw('Remove recipe?')),
        content: Text(
          '${ref.read(appTextProvider).raw('This removes')} "${meal.title}" ${ref.read(appTextProvider).raw('from ABCDish and hides it from the cooking feed.')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(ref.read(appTextProvider).raw('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(ref.read(appTextProvider).raw('Remove')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${meal.title}" ${ref.read(appTextProvider).raw('removed')}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      final handled = await redirectToLoginForAuthError(context, ref, error);
      if (handled || !context.mounted) return;

      logUiError('Recipe delete failed', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyErrorMessage(
              error,
              fallback: ref
                  .read(appTextProvider)
                  .raw('Unable to remove recipe'),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(managedMealsProvider);
    final text = ref.watch(appTextProvider);

    return Scaffold(
      appBar: AppBar(title: Text(text.raw('Manage Recipes'))),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.video_library_outlined, size: 56),
                const SizedBox(height: 12),
                Text(
                  text.raw('No recipe videos to manage yet'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  text.raw(
                    'If you have already uploaded a recipe, tap retry. Otherwise add your first recipe video.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(managedMealsProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(text.raw('Retry')),
                    ),
                    FilledButton.icon(
                      onPressed: () => _addRecipe(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(text.addRecipe),
                    ),
                  ],
                ),
              ],
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
        label: Text(text.addRecipe),
      ),
    );
  }

  Future<void> _addRecipe(BuildContext context, WidgetRef ref) async {
    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !context.mounted) return;

    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (ctx) => const CreatorUploadScreen()),
    );
    if (published == true) {
      ref.invalidate(mealsProvider);
      ref.invalidate(managedMealsProvider);
    }
  }
}

class _CreatorRecipeList extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(appTextProvider);

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
                text.raw('No recipe videos yet'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                text.raw(
                  'Upload an ABCDish-managed cooking video to start building the recipe catalog.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAddRecipe,
                icon: const Icon(Icons.add),
                label: Text(text.addRecipe),
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
        final thumbnailUrl = meal.imageUrl.trim();

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
                    label: Text(text.raw('Edit')),
                  ),
                  TextButton.icon(
                    onPressed: () => onDeleteRecipe(meal),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    label: Text(
                      text.raw('Remove'),
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
