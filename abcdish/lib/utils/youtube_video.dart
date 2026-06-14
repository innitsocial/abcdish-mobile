const _youtubeHosts = {
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'music.youtube.com',
  'youtu.be',
  'www.youtu.be',
};

bool isYouTubeUrl(String value) => extractYouTubeVideoId(value) != null;

String? extractYouTubeVideoId(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !_youtubeHosts.contains(uri.host.toLowerCase())) {
    return null;
  }

  String? id;

  if (uri.host.toLowerCase().endsWith('youtu.be')) {
    id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  } else if (uri.pathSegments.isNotEmpty) {
    final firstSegment = uri.pathSegments.first;

    if (firstSegment == 'watch') {
      id = uri.queryParameters['v'];
    } else if ((firstSegment == 'shorts' ||
            firstSegment == 'embed' ||
            firstSegment == 'live') &&
        uri.pathSegments.length > 1) {
      id = uri.pathSegments[1];
    }
  }

  if (id == null || id.isEmpty) return null;

  final cleanedId = id.split(RegExp(r'[?&#/]')).first.trim();
  if (!RegExp(r'^[A-Za-z0-9_-]{6,}$').hasMatch(cleanedId)) return null;

  return cleanedId;
}

String youtubeThumbnailUrl(String videoId) {
  return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}
