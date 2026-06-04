import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/partner_store.dart';
import 'package:abcdish/services/partner_store_service.dart';

final partnerStoresProvider = FutureProvider<List<PartnerStore>>((ref) async {
  try {
    return PartnerStoreService.instance.fetchStores();
  } catch (_) {
    return const [];
  }
});
