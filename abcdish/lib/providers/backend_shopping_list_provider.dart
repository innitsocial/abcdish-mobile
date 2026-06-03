import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/shopping_list_item.dart';
import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/services/backend_shopping_list_service.dart';

final backendShoppingListProvider = FutureProvider<List<ShoppingListItem>>((
  ref,
) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) {
    return const [];
  }
  return BackendShoppingListService.instance.fetchItems();
});
