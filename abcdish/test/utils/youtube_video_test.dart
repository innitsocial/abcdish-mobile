import 'package:flutter_test/flutter_test.dart';

import 'package:abcdish/utils/youtube_video.dart';

void main() {
  group('extractYouTubeVideoId', () {
    test('reads standard watch links', () {
      expect(
        extractYouTubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('reads short and shorts links', () {
      expect(
        extractYouTubeVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        extractYouTubeVideoId('https://youtube.com/shorts/dQw4w9WgXcQ?si=abc'),
        'dQw4w9WgXcQ',
      );
    });

    test('rejects non YouTube links', () {
      expect(extractYouTubeVideoId('https://example.com/video.mp4'), isNull);
      expect(isYouTubeUrl('https://cdn.abcdish.com/video.mp4'), isFalse);
    });
  });
}
