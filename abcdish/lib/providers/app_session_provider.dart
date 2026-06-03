import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/app_session.dart';
import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/services/app_session_service.dart';

final appSessionProvider = FutureProvider<AppSession?>((ref) async {
  final authState = ref.watch(authProvider);

  if (!authState.isLoggedIn) {
    return null;
  }

  return AppSessionService.instance.fetchSession();
});
