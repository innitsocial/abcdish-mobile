import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/providers/backend_shopping_list_provider.dart';
import 'package:abcdish/providers/shopping_list_provider.dart';
import 'package:abcdish/screens/partner_stores.dart';
import 'package:abcdish/services/backend_shopping_list_service.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  Future<void> _syncLocalItems(BuildContext context, WidgetRef ref) async {
    final localItems = ref.read(shoppingListProvider);
    if (localItems.isEmpty) return;

    try {
      for (final item in localItems) {
        await BackendShoppingListService.instance.addItem(ingredientName: item);
      }
      ref.read(shoppingListProvider.notifier).clearList();
      ref.invalidate(backendShoppingListProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shopping list synced to your account')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not sync shopping list: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!authState.isLoggedIn) {
      final shoppingItems = ref.watch(shoppingListProvider);
      return _LocalShoppingListView(
        items: shoppingItems,
        colorScheme: colorScheme,
        onRemove: (item) =>
            ref.read(shoppingListProvider.notifier).removeIngredient(item),
        onClear: () => ref.read(shoppingListProvider.notifier).clearList(),
      );
    }

    final backendItemsAsync = ref.watch(backendShoppingListProvider);
    final localItems = ref.watch(shoppingListProvider);

    return backendItemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load shopping list. $error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (items) {
        return Column(
          children: [
            if (localItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.sync),
                    title: Text('${localItems.length} local items not synced'),
                    subtitle: const Text('Sync them to your ABCDish account'),
                    trailing: FilledButton(
                      onPressed: () => _syncLocalItems(context, ref),
                      child: const Text('Sync'),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${items.length} items',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: items.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PartnerStoresScreen(
                                  checkoutMode: true,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.storefront),
                    label: const Text('Buy'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Your shopping list is empty. Add ingredients from a recipe.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.shopping_basket,
                              color: colorScheme.primary,
                            ),
                            title: Text(item.ingredientName),
                            subtitle:
                                item.quantity == null || item.quantity!.isEmpty
                                ? null
                                : Text(item.quantity!),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await BackendShoppingListService.instance
                                    .deleteItem(item.id);
                                ref.invalidate(backendShoppingListProvider);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LocalShoppingListView extends StatelessWidget {
  const _LocalShoppingListView({
    required this.items,
    required this.colorScheme,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> items;
  final ColorScheme colorScheme;
  final void Function(String item) onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Your shopping list is empty.\nAdd ingredients from a recipe.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(color: colorScheme.onSurface),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${items.length} local items',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.shopping_basket,
                    color: colorScheme.primary,
                  ),
                  title: Text(item),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onRemove(item),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
