import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/oauth_provider.dart';
import 'package:abcdish/services/oauth_service.dart';

final oauthProvidersProvider = FutureProvider<List<OAuthProviderOption>>((
  ref,
) async {
  return OAuthService.instance.fetchProviders();
});
