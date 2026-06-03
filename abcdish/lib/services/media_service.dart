import 'package:abcdish/models/media_upload.dart';
import 'package:abcdish/services/api_client.dart';

class MediaService {
  MediaService._internal();

  static final MediaService instance = MediaService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  Future<MediaUploadResponse> requestUpload(MediaUploadRequest request) async {
    final response = await _apiClient.post(
      '/api/media/upload',
      body: request.toJson(),
    );
    return MediaUploadResponse.fromJson(response as Map<String, dynamic>);
  }
}
