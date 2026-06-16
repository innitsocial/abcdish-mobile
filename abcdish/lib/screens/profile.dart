import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/l10n/app_text.dart';
import 'package:abcdish/providers/app_session_provider.dart';
import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/providers/language_provider.dart';
import 'package:abcdish/providers/theme_mode_provider.dart';
import 'package:abcdish/screens/login.dart';
import 'package:abcdish/screens/partner_stores.dart';
import 'package:abcdish/screens/register.dart';
import 'package:abcdish/utils/app_snack_bar.dart';
import 'package:abcdish/utils/error_messages.dart';

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

    ScaffoldMessenger.of(context).showSnackBar(
      successSnackBar(ref.read(appTextProvider).loggedOutSuccessfully),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.read(appTextProvider).raw('Delete account?')),
        content: Text(
          ref
              .read(appTextProvider)
              .raw(
                'This permanently deletes your ABCDish account, stories, comments, likes, sessions, and saved app data. This cannot be undone.',
              ),
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
            child: Text(ref.read(appTextProvider).raw('Delete')),
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
              ? ref.read(appTextProvider).raw('Your account has been deleted')
              : ref.read(authProvider).errorMessage ??
                    ref.read(appTextProvider).raw('Could not delete account'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final sessionAsync = ref.watch(appSessionProvider);
    final text = ref.watch(appTextProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!authState.isLoggedIn) {
      return _LoggedOutProfile(
        onLogin: () => _openLogin(context),
        onRegister: () => _openRegister(context),
      );
    }

    return sessionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        logUiError('Profile load failed', error, stackTrace);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(Icons.error_outline, size: 60),
            const SizedBox(height: 16),
            Text(
              text.raw('Could not load profile'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userFriendlyErrorMessage(
                error,
                fallback: text.raw(
                  'Please try again. If this keeps happening, logout and sign in again.',
                ),
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(appSessionProvider),
              icon: const Icon(Icons.refresh),
              label: Text(text.raw('Try again')),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(text.raw('Logout')),
            ),
          ],
        );
      },
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
                  ? '${text.raw('Welcome')} ${session.name}'
                  : text.raw('Welcome back'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPaid
                  ? text.raw('ABCDish Member: unlimited cooking videos.')
                  : '${text.raw('Free plan')}: ${session.remainingViews} ${text.raw('videos remaining this month')}.',
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
                title: Text(
                  isPaid ? text.raw('ABCDish Member') : text.raw('Free Plan'),
                ),
                subtitle: Text(
                  isPaid
                      ? text.raw('Unlimited videos enabled')
                      : '${session.monthlyVideoViews} ${text.raw('used')} • ${session.remainingViews} ${text.raw('remaining')}',
                ),
                trailing: session.features.shouldShowUpgrade
                    ? FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                text.raw('Membership upgrade coming soon'),
                              ),
                            ),
                          );
                        },
                        child: Text(text.raw('Upgrade')),
                      )
                    : const Icon(Icons.check_circle),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(text.raw('Account verification')),
                subtitle: Text(
                  '${text.email}: ${session.emailVerified ? text.raw("Verified") : text.raw("Not verified")}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.storefront,
              title: text.raw('Partner Stores'),
              subtitle: text.raw('Browse stores connected to shopping lists'),
              onTap: () => _open(context, const PartnerStoresScreen()),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(text.raw('Logout')),
            ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(text.aboutAbcdish),
              subtitle: Text(text.anyBuddyCanDish),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(text.raw('Privacy Policy')),
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
                  text.raw('Delete account'),
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: Text(
                  text.raw('Permanently remove your account and personal data'),
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

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.read(languageProvider);
    final text = ref.read(appTextProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) => SafeArea(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: supportedAppLanguages.length + 1,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.chooseLanguage,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${supportedAppLanguages.length} languages',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final language = supportedAppLanguages[index - 1];
              final isSelected = language.code == selectedLanguage.code;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.translate,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(language.nativeName),
                subtitle: Text(language.name),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage(language);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appLanguage = ref.watch(languageProvider);
    final text = ref.watch(appTextProvider);
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
                  text.settings,
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
                    text.appearance,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(text.light),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(text.dark),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.translate, color: colorScheme.primary),
              title: Text(text.language),
              subtitle: Text('${appLanguage.nativeName} · ${appLanguage.name}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(context, ref),
            ),
            const SizedBox(height: 6),
            Text(
              text.languageHelp,
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

class _LoggedOutProfile extends ConsumerWidget {
  const _LoggedOutProfile({required this.onLogin, required this.onRegister});

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(appTextProvider);
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
          text.welcomeToAbcdish,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text.loggedOutHelp,
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
          label: Text(text.login),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRegister,
          icon: const Icon(Icons.person_add),
          label: Text(text.createAccount),
        ),
        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(text.aboutAbcdish),
          subtitle: Text(text.anyBuddyCanDish),
        ),
      ],
    );
  }
}
