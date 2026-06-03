import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/partner_store.dart';
import 'package:abcdish/providers/partner_store_provider.dart';

class PartnerStoresScreen extends ConsumerWidget {
  const PartnerStoresScreen({super.key, this.checkoutMode = false});

  final bool checkoutMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(
      checkoutMode ? checkoutPartnerStoresProvider : partnerStoresProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(checkoutMode ? 'Buy Shopping List' : 'Partner Stores'),
      ),
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load partner stores. $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (stores) {
          if (stores.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No partner stores available yet. ABCDish will add local grocery partners soon.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stores.length,
            itemBuilder: (context, index) =>
                _PartnerStoreCard(store: stores[index]),
          );
        },
      ),
    );
  }
}

class _PartnerStoreCard extends StatelessWidget {
  const _PartnerStoreCard({required this.store});

  final PartnerStore store;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.storefront)),
        title: Text(store.storeName),
        subtitle: Text(
          [
            if (store.postcode.isNotEmpty) store.postcode,
            if (store.websiteUrl.isNotEmpty) store.websiteUrl,
          ].join('\n'),
        ),
        trailing: FilledButton(
          onPressed: store.websiteUrl.isEmpty
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Open partner checkout: ${store.websiteUrl}',
                      ),
                    ),
                  );
                },
          child: const Text('Buy'),
        ),
      ),
    );
  }
}
