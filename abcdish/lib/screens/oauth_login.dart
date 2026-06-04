import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/oauth_provider_info.dart';
import 'package:abcdish/services/oauth_service.dart';

final oauthProvidersProvider = FutureProvider<List<OAuthProviderInfo>>((ref) {
  return OAuthService.instance.fetchProviders();
});

class OAuthLoginScreen extends ConsumerWidget {
  const OAuthLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(oauthProvidersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Social Login')),
      body: providersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load OAuth providers.\n\n$error'),
          ),
        ),
        data: (providers) {
          if (providers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'OAuth providers are configured in the backend and will be enabled after provider credentials are added.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.login),
                  title: Text('Continue with ${provider.provider}'),
                  subtitle: Text(provider.message),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'OAuth redirect: ${provider.authorizationUrl}',
                        ),
                      ),
                    );
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
