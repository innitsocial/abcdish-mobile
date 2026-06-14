import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:abcdish/screens/login.dart';
import 'package:abcdish/services/api_client.dart';
import 'package:abcdish/services/story_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _picker = ImagePicker();

  VideoPlayerController? _previewController;
  String _title = '';
  String _caption = '';
  String? _localVideoPath;
  bool _loadingPreview = false;
  bool _previewFailed = false;
  bool _submitting = false;
  bool _cameraOpenedOnStart = false;
  bool _showVideoUrlField = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_syncText);
    _captionController.addListener(_syncText);
    _videoUrlController.addListener(_syncText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cameraOpenedOnStart && mounted) {
        _cameraOpenedOnStart = true;
        _pickVideo(ImageSource.camera);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _videoUrlController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  void _syncText() {
    setState(() {
      _title = _titleController.text.trim();
      _caption = _captionController.text.trim();
    });
  }

  Future<void> _loadPreview() async {
    final url = _videoUrlController.text.trim();
    final uri = Uri.tryParse(url);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() {
        _previewFailed = true;
      });
      return;
    }

    setState(() {
      _localVideoPath = null;
      _showVideoUrlField = true;
    });

    setState(() {
      _loadingPreview = true;
      _previewFailed = false;
    });

    final previousController = _previewController;
    _previewController = null;
    await previousController?.dispose();

    try {
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _previewController = controller;
        _loadingPreview = false;
      });

      await controller.play();
    } catch (error) {
      debugPrint('Story preview error: $error');
      if (!mounted) return;

      setState(() {
        _loadingPreview = false;
        _previewFailed = true;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );

      if (video == null || !mounted) return;

      setState(() {
        _loadingPreview = true;
        _previewFailed = false;
        _localVideoPath = video.path;
      });

      final previousController = _previewController;
      _previewController = null;
      await previousController?.dispose();

      final controller = VideoPlayerController.file(File(video.path));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _previewController = controller;
        _loadingPreview = false;
        _showVideoUrlField = false;
      });

      await controller.play();
    } catch (error) {
      debugPrint('Story video pick error: $error');
      if (!mounted) return;

      setState(() {
        _loadingPreview = false;
        _previewFailed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open video picker. $error')),
      );
    }
  }

  Future<void> _publishStory() async {
    if (!_formKey.currentState!.validate()) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (_localVideoPath == null && _videoUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose camera, gallery, or video URL.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final story = await StoryService.instance.createStory(
        title: _titleController.text.trim(),
        caption: _captionController.text.trim(),
        videoUrl: _videoUrlController.text.trim(),
        localVideoPath: _localVideoPath,
      );

      if (!mounted) return;
      Navigator.of(context).pop(story);
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to post story. $error')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showVideoUrl() {
    setState(() {
      _showVideoUrlField = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Form(
          key: _formKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _StoryCanvas(
                title: _title,
                caption: _caption,
                loadingPreview: _loadingPreview,
                previewFailed: _previewFailed,
                controller: _previewController,
                hasLocalVideo: _localVideoPath != null,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton.filled(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.48),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Story',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _publishStory,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _StoryComposerTray(
                  titleController: _titleController,
                  captionController: _captionController,
                  videoUrlController: _videoUrlController,
                  loadingPreview: _loadingPreview,
                  submitting: _submitting,
                  showVideoUrlField: _showVideoUrlField,
                  onPreview: _loadPreview,
                  onCamera: () => _pickVideo(ImageSource.camera),
                  onGallery: () => _pickVideo(ImageSource.gallery),
                  onVideoUrl: _showVideoUrl,
                  onShare: _publishStory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCanvas extends StatelessWidget {
  const _StoryCanvas({
    required this.title,
    required this.caption,
    required this.loadingPreview,
    required this.previewFailed,
    required this.controller,
    required this.hasLocalVideo,
  });

  final String title;
  final String caption;
  final bool loadingPreview;
  final bool previewFailed;
  final VideoPlayerController? controller;
  final bool hasLocalVideo;

  @override
  Widget build(BuildContext context) {
    final previewController = controller;
    final hasVideo =
        previewController != null && previewController.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasVideo)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewController.value.size.width,
              height: previewController.value.size.height,
              child: VideoPlayer(previewController),
            ),
          )
        else
          const _EmptyStoryBackdrop(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.42),
                Colors.black.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.86),
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
        if (loadingPreview)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        Positioned(
          left: 22,
          right: 22,
          bottom: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (previewFailed)
                const _StoryNotice(
                  icon: Icons.error_outline,
                  label: 'Video preview unavailable',
                ),
              if (hasLocalVideo && hasVideo)
                const _StoryNotice(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Ready to upload',
                ),
              if (!hasVideo && !loadingPreview && !previewFailed)
                const _StoryNotice(
                  icon: Icons.videocam_outlined,
                  label: 'Add your cooking video',
                ),
              if (title.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 18),
                    ],
                  ),
                ),
              ],
              if (caption.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  caption,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 14),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyStoryBackdrop extends StatelessWidget {
  const _EmptyStoryBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.2, -0.45),
          radius: 1.15,
          colors: [
            const Color(0xFF3B2620),
            const Color(0xFF111111),
            Colors.black.withValues(alpha: 1),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_menu, color: Colors.white24, size: 96),
      ),
    );
  }
}

class _StoryNotice extends StatelessWidget {
  const _StoryNotice({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryComposerTray extends StatelessWidget {
  const _StoryComposerTray({
    required this.titleController,
    required this.captionController,
    required this.videoUrlController,
    required this.loadingPreview,
    required this.submitting,
    required this.showVideoUrlField,
    required this.onPreview,
    required this.onCamera,
    required this.onGallery,
    required this.onVideoUrl,
    required this.onShare,
  });

  final TextEditingController titleController;
  final TextEditingController captionController;
  final TextEditingController videoUrlController;
  final bool loadingPreview;
  final bool submitting;
  final bool showVideoUrlField;
  final VoidCallback onPreview;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onVideoUrl;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ComposerIconButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onPressed: onCamera,
                      ),
                      const SizedBox(width: 10),
                      _ComposerIconButton(
                        icon: Icons.video_library_outlined,
                        label: 'Gallery',
                        onPressed: onGallery,
                      ),
                      const SizedBox(width: 10),
                      _ComposerIconButton(
                        icon: Icons.link,
                        label: 'URL',
                        onPressed: onVideoUrl,
                      ),
                      const SizedBox(width: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'story',
                            label: Text('Story'),
                            icon: Icon(Icons.history_toggle_off),
                          ),
                        ],
                        selected: const {'story'},
                        onSelectionChanged: (_) {},
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          selectedForegroundColor: Colors.black,
                          selectedBackgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showVideoUrlField) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: videoUrlController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    decoration: _darkInputDecoration(
                      label: 'Video link',
                      hint: 'https://...mp4',
                      icon: Icons.link,
                      suffix: IconButton(
                        onPressed: loadingPreview ? null : onPreview,
                        icon: loadingPreview
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_circle_outline),
                        tooltip: 'Preview video',
                      ),
                    ),
                    validator: (value) {
                      final videoUrl = value?.trim() ?? '';
                      if (videoUrl.isEmpty) {
                        return 'Add a video link';
                      }
                      final uri = Uri.tryParse(videoUrl);
                      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                        return 'Enter a valid video link';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => onPreview(),
                  ),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  decoration: _darkInputDecoration(
                    label: 'Title',
                    hint: 'What are you cooking?',
                    icon: Icons.text_fields,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Add a story title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: captionController,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.done,
                  minLines: 1,
                  maxLines: 2,
                  maxLength: 220,
                  decoration: _darkInputDecoration(
                    label: 'Caption',
                    hint: 'Add a quick note',
                    icon: Icons.notes_outlined,
                  ),
                  onFieldSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: submitting ? null : onShare,
                    icon: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text('Share story'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _darkInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white24),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white10,
      counterStyle: const TextStyle(color: Colors.white54),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIconColor: Colors.white70,
      suffixIconColor: Colors.white70,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFFF8A80)),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFFF8A80)),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white10,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
