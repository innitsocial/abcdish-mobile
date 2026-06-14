import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/app_session.dart';
import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/services/api_client.dart';
import 'package:abcdish/services/app_session_service.dart';
import 'package:abcdish/services/auth_service.dart';

final appSessionProvider = FutureProvider<AppSession?>((ref) async {
  final authState = ref.watch(authProvider);

  if (!authState.isLoggedIn) {
    return null;
  }

  try {
    return await AppSessionService.instance.fetchSession();
  } on ApiException catch (error) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      await AuthService.instance.logout();
      ref.read(authProvider.notifier).markLoggedOut();
      return null;
    }

    rethrow;
  }
});
