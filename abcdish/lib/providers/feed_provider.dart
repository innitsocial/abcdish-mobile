import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/feed_item.dart';
import 'package:abcdish/providers/meals_provider.dart';
import 'package:abcdish/services/feed_service.dart';

final feedProvider = FutureProvider<List<FeedItem>>((ref) async {
  try {
    final page = await FeedService.instance.fetchFeed();
    return page.items;
  } catch (_) {
    final meals = await ref.watch(mealsProvider.future);
    return FeedService.instance.fallbackFromMeals(meals);
  }
});
