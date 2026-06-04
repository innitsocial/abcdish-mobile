import 'package:abcdish/models/meal.dart';
import 'package:abcdish/services/api_client.dart';

class FeedService {
  FeedService._internal();

  static final FeedService instance = FeedService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<Meal>> fetchFeed() async {
    final response = await _apiClient.get('/api/feed');

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(Meal.fromJson)
          .toList();
    }

    if (response is Map<String, dynamic> && response['items'] is List) {
      return (response['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Meal.fromJson)
          .toList();
    }

    return [];
  }
}
