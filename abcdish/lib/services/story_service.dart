import 'package:abcdish/models/story.dart';
import 'package:abcdish/services/api_client.dart';

class StoryService {
  StoryService._internal();

  static final StoryService instance = StoryService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<List<Story>> fetchStories() async {
    final response = await _apiClient.get('/api/stories');

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(Story.fromJson)
          .toList();
    }

    return [];
  }

  Future<Story> createStory({
    required String title,
    required String caption,
    required String videoUrl,
    String? localVideoPath,
  }) async {
    final resolvedVideoUrl = localVideoPath == null
        ? videoUrl
        : await uploadStoryVideo(localVideoPath);

    if (resolvedVideoUrl.trim().isEmpty) {
      throw Exception('Video upload did not return a playable URL');
    }

    final response = await _apiClient.post(
      '/api/stories',
      body: {
        'title': title,
        'caption': caption,
        'imageUrl': '',
        'videoUrl': resolvedVideoUrl,
      },
    );

    return Story.fromJson(response as Map<String, dynamic>);
  }

  Future<String> uploadStoryVideo(String filePath) async {
    final response = await _apiClient.uploadFile(
      '/api/media/story-video',
      fieldName: 'file',
      filePath: filePath,
    );

    if (response is Map<String, dynamic>) {
      return response['publicUrl']?.toString() ?? '';
    }

    return '';
  }
}
