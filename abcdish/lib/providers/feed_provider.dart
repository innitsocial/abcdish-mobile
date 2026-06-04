import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/meal.dart';
import 'package:abcdish/providers/meals_provider.dart';
import 'package:abcdish/services/feed_service.dart';

final feedProvider = FutureProvider<List<Meal>>((ref) async {
  try {
    final feedItems = await FeedService.instance.fetchFeed();
    if (feedItems.isNotEmpty) return feedItems;
  } catch (_) {
    // Fall back to meals if feed endpoint is unavailable.
  }

  return ref.watch(mealsProvider.future);
});
