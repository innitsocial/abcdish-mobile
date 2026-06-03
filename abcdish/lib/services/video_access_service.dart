import 'package:abcdish/models/video_access.dart';
import 'package:abcdish/services/api_client.dart';

class VideoAccessService {
  VideoAccessService._internal();

  static final VideoAccessService instance = VideoAccessService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<VideoAccess> recordVideoView(String mealId) async {
    final response = await _apiClient.post('/api/video-views/$mealId');

    return VideoAccess.fromJson(response as Map<String, dynamic>);
  }
}
