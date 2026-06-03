import 'package:abcdish/models/feed_item.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/services/api_client.dart';

class FeedPage {
  const FeedPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<FeedItem> items;
  final int page;
  final bool hasMore;
}

class FeedService {
  FeedService._internal();

  static final FeedService instance = FeedService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<FeedPage> fetchFeed({int page = 0, int size = 10}) async {
    final response = await _apiClient.get('/api/feed?page=$page&size=$size');

    if (response is List) {
      return FeedPage(
        items: response
            .map((item) => FeedItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        page: page,
        hasMore: response.length >= size,
      );
    }

    final data = response as Map<String, dynamic>;
    final rawItems = data['items'] ?? data['content'] ?? data['feed'] ?? [];

    return FeedPage(
      items: (rawItems as List)
          .map((item) => FeedItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: int.tryParse(data['page']?.toString() ?? '') ?? page,
      hasMore: data['hasMore'] == true || data['last'] == false,
    );
  }

  List<FeedItem> fallbackFromMeals(List<Meal> meals) {
    return meals.map(FeedItem.fromMeal).toList();
  }
}
