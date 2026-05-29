import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/screens/login.dart';
import 'package:abcdish/screens/register.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => const LoginScreen()));
  }

  void _openRegister(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => const RegisterScreen()));
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            authState.isLoggedIn ? Icons.verified_user : Icons.person,
            size: 52,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          authState.isLoggedIn ? 'Welcome back' : 'Welcome to ABCDish',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          authState.isLoggedIn
              ? 'Your favourites and shopping list can now be synced with your account.'
              : 'Login to save favourites and shopping lists across devices.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (!authState.isLoggedIn) ...[
          FilledButton.icon(
            onPressed: () => _openLogin(context),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openRegister(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Create Account'),
          ),
        ] else ...[
          FilledButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
        const SizedBox(height: 24),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('About ABCDish'),
          subtitle: Text('Any Buddy Can Dish'),
        ),
        const ListTile(
          leading: Icon(Icons.privacy_tip_outlined),
          title: Text('Privacy Policy'),
        ),
        const ListTile(
          leading: Icon(Icons.settings_outlined),
          title: Text('Settings'),
        ),
      ],
    );
  }
}
