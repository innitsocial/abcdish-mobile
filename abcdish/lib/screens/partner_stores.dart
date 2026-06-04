import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/partner_store_provider.dart';

class PartnerStoresScreen extends ConsumerWidget {
  const PartnerStoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(partnerStoresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Stores')),
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load partner stores.\n\n$error'),
          ),
        ),
        data: (stores) {
          if (stores.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Partner stores coming soon.\nABCDish will help users buy ingredients from local stores.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.storefront),
                  title: Text(store.storeName),
                  subtitle: Text(store.postcode),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(store.websiteUrl)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
