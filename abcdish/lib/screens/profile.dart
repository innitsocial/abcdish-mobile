import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/app_session_provider.dart';
import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/providers/language_provider.dart';
import 'package:abcdish/providers/theme_mode_provider.dart';
import 'package:abcdish/screens/creator_recipes.dart';
import 'package:abcdish/screens/login.dart';
import 'package:abcdish/screens/partner_stores.dart';
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

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => screen));
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();

    ref.invalidate(appSessionProvider);

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your ABCDish account, stories, comments, likes, sessions, and saved app data. This cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await ref.read(authProvider.notifier).deleteAccount();
    ref.invalidate(appSessionProvider);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Your account has been deleted'
              : ref.read(authProvider).errorMessage ??
                    'Could not delete account',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final sessionAsync = ref.watch(appSessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!authState.isLoggedIn) {
      return _LoggedOutProfile(
        onLogin: () => _openLogin(context),
        onRegister: () => _openRegister(context),
      );
    }

    return sessionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.error_outline, size: 60),
          const SizedBox(height: 16),
          Text(
            'Could not load profile',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again. If this keeps happening, logout and sign in again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => ref.invalidate(appSessionProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
      data: (session) {
        if (session == null) {
          return _LoggedOutProfile(
            onLogin: () => _openLogin(context),
            onRegister: () => _openRegister(context),
          );
        }

        final isPaid = session.membershipStatus == 'ACTIVE';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                isPaid ? Icons.workspace_premium : Icons.person,
                size: 52,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              session.name?.isNotEmpty == true
                  ? 'Welcome ${session.name}'
                  : 'Welcome back',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPaid
                  ? 'ABCDish Member: unlimited cooking videos.'
                  : 'Free plan: ${session.remainingViews} videos remaining this month.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.workspace_premium,
                  color: colorScheme.primary,
                ),
                title: Text(isPaid ? 'ABCDish Member' : 'Free Plan'),
                subtitle: Text(
                  isPaid
                      ? 'Unlimited videos enabled'
                      : '${session.monthlyVideoViews} used • ${session.remainingViews} remaining',
                ),
                trailing: session.features.shouldShowUpgrade
                    ? FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Membership upgrade coming soon'),
                            ),
                          );
                        },
                        child: const Text('Upgrade'),
                      )
                    : const Icon(Icons.check_circle),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Account verification'),
                subtitle: Text(
                  'Email: ${session.emailVerified ? "Verified" : "Not verified"}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.video_call,
              title: 'Creator Studio',
              subtitle: 'Manage, edit, remove, and publish recipes',
              onTap: () => _open(context, const CreatorRecipesScreen()),
            ),
            _ProfileTile(
              icon: Icons.storefront,
              title: 'Partner Stores',
              subtitle: 'Browse stores connected to shopping lists',
              onTap: () => _open(context, const PartnerStoresScreen()),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
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
            const _ThemeSettingsCard(),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Delete account',
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: const Text(
                  'Permanently remove your account and personal data',
                ),
                onTap: () => _deleteAccount(context, ref),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ThemeSettingsCard extends ConsumerWidget {
  const _ThemeSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appLanguage = ref.watch(languageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Language',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                DropdownButton<AppLanguage>(
                  value: appLanguage,
                  items: supportedAppLanguages
                      .map(
                        (language) => DropdownMenuItem(
                          value: language,
                          child: Text(language.nativeName),
                        ),
                      )
                      .toList(),
                  onChanged: (language) {
                    if (language == null) return;
                    ref.read(languageProvider.notifier).setLanguage(language);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'AI recipe text and generated video metadata will use this language.',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedOutProfile extends StatelessWidget {
  const _LoggedOutProfile({required this.onLogin, required this.onRegister});

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            size: 52,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to ABCDish',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to save favourites, shopping lists and watch more videos.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onLogin,
          icon: const Icon(Icons.login),
          label: const Text('Login'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRegister,
          icon: const Icon(Icons.person_add),
          label: const Text('Create Account'),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('About ABCDish'),
          subtitle: Text('Any Buddy Can Dish'),
        ),
      ],
    );
  }
}
