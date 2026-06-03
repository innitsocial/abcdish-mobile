import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/oauth_provider.dart';
import 'package:abcdish/providers/oauth_provider.dart';
import 'package:abcdish/services/oauth_service.dart';

class OAuthLoginScreen extends ConsumerWidget {
  const OAuthLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(oauthProvidersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Continue with Social Login')),
      body: providersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load OAuth providers. $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (providers) {
          final effectiveProviders = providers.isEmpty
              ? const [
                  OAuthProviderOption(
                    provider: 'GOOGLE',
                    displayName: 'Google',
                    authorizationUrl: '',
                    enabled: true,
                  ),
                  OAuthProviderOption(
                    provider: 'APPLE',
                    displayName: 'Apple',
                    authorizationUrl: '',
                    enabled: true,
                  ),
                  OAuthProviderOption(
                    provider: 'FACEBOOK',
                    displayName: 'Facebook',
                    authorizationUrl: '',
                    enabled: true,
                  ),
                  OAuthProviderOption(
                    provider: 'MICROSOFT',
                    displayName: 'Microsoft',
                    authorizationUrl: '',
                    enabled: true,
                  ),
                ]
              : providers;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'OAuth providers',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'These buttons call your backend OAuth start endpoints. Browser redirect/token exchange can be completed when provider credentials are configured.',
              ),
              const SizedBox(height: 20),
              for (final provider in effectiveProviders)
                Card(
                  child: ListTile(
                    leading: Icon(_providerIcon(provider.provider)),
                    title: Text('Continue with ${provider.displayName}'),
                    subtitle: provider.authorizationUrl.isEmpty
                        ? const Text(
                            'Provider configured in backend placeholder',
                          )
                        : Text(provider.authorizationUrl),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: provider.enabled,
                    onTap: provider.enabled
                        ? () async {
                            try {
                              final started = await OAuthService.instance
                                  .startProvider(provider.provider);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    started.authorizationUrl.isEmpty
                                        ? '${provider.displayName} OAuth is ready to configure'
                                        : 'Open: ${started.authorizationUrl}',
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('OAuth start failed: $error'),
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _providerIcon(String provider) {
    switch (provider.toUpperCase()) {
      case 'APPLE':
        return Icons.apple;
      case 'FACEBOOK':
        return Icons.facebook;
      case 'MICROSOFT':
        return Icons.window;
      default:
        return Icons.login;
    }
  }
}
