import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/shopping_list_provider.dart';
import 'package:abcdish/screens/partner_stores.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingItems = ref.watch(shoppingListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (shoppingItems.isEmpty) {
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
                '${shoppingItems.length} items',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ref.read(shoppingListProvider.notifier).clearList();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shopping list cleared')),
                  );
                },
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const PartnerStoresScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.storefront),
              label: const Text('Find Partner Stores'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shoppingItems.length,
            itemBuilder: (context, index) {
              final item = shoppingItems[index];

              return Dismissible(
                key: ValueKey(item),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 8),
                  color: colorScheme.error,
                  child: Icon(Icons.delete, color: colorScheme.onError),
                ),
                onDismissed: (_) {
                  ref
                      .read(shoppingListProvider.notifier)
                      .removeIngredient(item);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$item removed')));
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.shopping_basket_outlined,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      item,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    trailing: const Icon(Icons.drag_handle),
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
