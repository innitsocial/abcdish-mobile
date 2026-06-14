import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/screens/login.dart';
import 'package:abcdish/services/api_client.dart';

bool isAuthError(Object error) {
  return error is ApiException &&
      (error.statusCode == 401 || error.statusCode == 403);
}

Future<bool> ensureLoggedIn(BuildContext context, WidgetRef ref) async {
  if (ref.read(authProvider).isLoggedIn) {
    return true;
  }

  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
  await ref.read(authProvider.notifier).checkLoginStatus();

  return ref.read(authProvider).isLoggedIn;
}

Future<bool> redirectToLoginForAuthError(
  BuildContext context,
  WidgetRef ref,
  Object error,
) async {
  if (!isAuthError(error)) {
    return false;
  }

  ref.read(authProvider.notifier).markLoggedOut();
  if (!context.mounted) return true;

  await ensureLoggedIn(context, ref);
  return true;
}
