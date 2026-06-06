import 'package:abcdish/models/feed_comment.dart';
import 'package:abcdish/services/api_client.dart';

class SocialService {
  SocialService._internal();

  static final SocialService instance = SocialService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<void> likeMeal(String mealId) async {
    await _apiClient.post('/api/social/meals/$mealId/likes');
  }

  Future<void> unlikeMeal(String mealId) async {
    await _apiClient.delete('/api/social/meals/$mealId/likes');
  }

  Future<void> shareMeal(String mealId) async {
    await _apiClient.post('/api/social/meals/$mealId/shares');
  }

  Future<void> followCreator(String creatorKey) async {
    final encodedCreatorKey = Uri.encodeComponent(creatorKey);
    await _apiClient.post('/api/social/creators/$encodedCreatorKey/follow');
  }

  Future<void> unfollowCreator(String creatorKey) async {
    final encodedCreatorKey = Uri.encodeComponent(creatorKey);
    await _apiClient.delete('/api/social/creators/$encodedCreatorKey/follow');
  }

  Future<List<FeedComment>> fetchComments(String mealId) async {
    final response = await _apiClient.get('/api/social/meals/$mealId/comments');

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(FeedComment.fromJson)
          .toList();
    }

    return [];
  }

  Future<FeedComment> addComment(String mealId, String text) async {
    final response = await _apiClient.post(
      '/api/social/meals/$mealId/comments',
      body: {'text': text},
    );

    return FeedComment.fromJson(response as Map<String, dynamic>);
  }
}
