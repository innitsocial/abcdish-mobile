import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubeRecipePlayer extends StatefulWidget {
  const YoutubeRecipePlayer({super.key, required this.videoId});

  final String videoId;

  @override
  State<YoutubeRecipePlayer> createState() => _YoutubeRecipePlayerState();
}

class _YoutubeRecipePlayerState extends State<YoutubeRecipePlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  @override
  void didUpdateWidget(covariant YoutubeRecipePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoId != widget.videoId) {
      _controller.close();
      _controller = _buildController();
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  YoutubePlayerController _buildController() {
    return YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        playsInline: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: YoutubePlayer(controller: _controller),
    );
  }
}
