import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/app_session_provider.dart';
import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/screens/creator_upload.dart';
import 'package:abcdish/screens/login.dart';
import 'package:abcdish/screens/oauth_login.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final sessionAsync = ref.watch(appSessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!authState.isLoggedIn) {
      return _LoggedOutProfile(
        onLogin: () => _openLogin(context),
        onRegister: () => _openRegister(context),
        onOAuth: () => _open(context, const OAuthLoginScreen()),
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
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 24),
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
            onOAuth: () => _open(context, const OAuthLoginScreen()),
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
                  'Email: ${session.emailVerified ? "Verified" : "Not verified"}\n'
                  'Mobile: ${session.mobileVerified ? "Verified" : "Not verified"}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Role'),
                subtitle: Text(session.role),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.video_call,
              title: 'Creator Studio',
              subtitle: 'Upload recipe drafts and cooking videos',
              onTap: () => _open(context, const CreatorUploadScreen()),
            ),
            _ProfileTile(
              icon: Icons.storefront,
              title: 'Partner Stores',
              subtitle: 'Browse stores connected to shopping lists',
              onTap: () => _open(context, const PartnerStoresScreen()),
            ),
            _ProfileTile(
              icon: Icons.login,
              title: 'Social Login Providers',
              subtitle: 'Google, Apple, Facebook and Microsoft foundations',
              onTap: () => _open(context, const OAuthLoginScreen()),
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
            const ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Settings'),
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

class _LoggedOutProfile extends StatelessWidget {
  const _LoggedOutProfile({
    required this.onLogin,
    required this.onRegister,
    required this.onOAuth,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onOAuth;

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
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onOAuth,
          icon: const Icon(Icons.alternate_email),
          label: const Text('Social Login'),
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
