import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MealVideoPlayer extends StatefulWidget {
  const MealVideoPlayer({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<MealVideoPlayer> createState() => _MealVideoPlayerState();
}

class _MealVideoPlayerState extends State<MealVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _setupVideoPlayer() async {
    if (_isLoading || _chewieController != null) return;

    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Video is not available.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        aspectRatio: controller.value.aspectRatio,
      );

      setState(() {
        _videoPlayerController = controller;
        _chewieController = chewieController;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('MealVideoPlayer error: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load cooking video.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;
    final videoController = _videoPlayerController;

    if (chewieController != null && videoController != null) {
      return AspectRatio(
        aspectRatio: videoController.value.aspectRatio,
        child: Chewie(controller: chewieController),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: _setupVideoPlayer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Video'),
                  ),
                ],
              ),
      ),
    );
  }
}
