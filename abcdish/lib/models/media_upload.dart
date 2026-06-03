class MediaUploadRequest {
  const MediaUploadRequest({
    required this.fileName,
    required this.contentType,
    required this.mediaType,
  });

  final String fileName;
  final String contentType;
  final String mediaType;

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'contentType': contentType,
      'mediaType': mediaType,
    };
  }
}

class MediaUploadResponse {
  const MediaUploadResponse({
    required this.uploadUrl,
    required this.publicUrl,
    required this.mediaId,
  });

  final String uploadUrl;
  final String publicUrl;
  final String mediaId;

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      uploadUrl: json['uploadUrl']?.toString() ?? '',
      publicUrl:
          json['publicUrl']?.toString() ?? json['mediaUrl']?.toString() ?? '',
      mediaId: json['mediaId']?.toString() ?? json['id']?.toString() ?? '',
    );
  }
}
