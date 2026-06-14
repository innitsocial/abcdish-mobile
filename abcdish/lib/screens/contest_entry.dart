import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:abcdish/models/contest.dart';
import 'package:abcdish/services/contest_service.dart';
import 'package:abcdish/services/meal_service.dart';
import 'package:abcdish/utils/auth_navigation.dart';

class ContestEntryScreen extends ConsumerStatefulWidget {
  const ContestEntryScreen({super.key, required this.contest});

  final Contest contest;

  @override
  ConsumerState<ContestEntryScreen> createState() => _ContestEntryScreenState();
}

class _ContestEntryScreenState extends ConsumerState<ContestEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  String _competitionCategory = 'dinner';
  String _title = '';
  String _description = '';
  String _videoUrl = '';
  String? _localVideoPath;
  bool _uploadingVideo = false;
  bool _submitting = false;
  bool _soundFreeConfirmed = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !mounted) return;

    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null || !mounted) return;

      setState(() {
        _uploadingVideo = true;
        _localVideoPath = video.path;
      });

      final uploadedUrl = await MealService.instance.uploadRecipeVideo(
        video.path,
      );
      if (!mounted) return;

      setState(() {
        _videoUrl = uploadedUrl;
      });
    } catch (error) {
      if (!mounted) return;
      final handled = await redirectToLoginForAuthError(context, ref, error);
      if (handled || !mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Video upload failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _uploadingVideo = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !mounted) return;

    _formKey.currentState!.save();

    if (_videoUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload your competition video first')),
      );
      return;
    }

    if (!_soundFreeConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirm your video is sound-free before submitting.'),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final moderationStatus = await ContestService.instance.submitEntry(
        contestId: widget.contest.id,
        title: _title,
        description: _description,
        videoUrl: _videoUrl,
        soundFreeConfirmed: _soundFreeConfirmed,
        competitionCategory: _competitionCategory,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            moderationStatus == 'APPROVED'
                ? 'Contest entry is live'
                : 'Contest entry submitted and pending review',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final handled = await redirectToLoginForAuthError(context, ref, error);
      if (handled || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry submission failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Contest Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    widget.contest.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Entry title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Enter a title';
                      }
                      return null;
                    },
                    onSaved: (value) => _title = value!.trim(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _competitionCategory,
                    decoration: const InputDecoration(
                      labelText: 'Competition category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'breakfast',
                        child: Text('Breakfast'),
                      ),
                      DropdownMenuItem(value: 'drink', child: Text('Drink')),
                      DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                      DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                      DropdownMenuItem(
                        value: 'dessert',
                        child: Text('Dessert'),
                      ),
                      DropdownMenuItem(value: 'snack', child: Text('Snack')),
                      DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _competitionCategory = value ?? 'dinner';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Short description',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 3,
                    onSaved: (value) => _description = value?.trim() ?? '',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'For trust, ABCDish only accepts sound-free recipe videos. After review, AI narration can be added in different languages so people can follow the recipe clearly.',
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.video_file_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _videoUrl.isEmpty
                                      ? 'Competition video'
                                      : 'Video uploaded',
                                  style: Theme.of(context).textTheme.titleSmall!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _videoUrl.isEmpty
                                ? 'Upload your cooking video. People will vote by liking it.'
                                : 'Your video is uploaded and ready for the contest.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_localVideoPath != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _localVideoPath!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _uploadingVideo ? null : _pickVideo,
                            icon: _uploadingVideo
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(
                              _uploadingVideo
                                  ? 'Uploading...'
                                  : _videoUrl.isEmpty
                                  ? 'Upload Video'
                                  : 'Replace Video',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FormField<String>(
                    validator: (value) {
                      if (_videoUrl.trim().isEmpty) {
                        return 'Upload your competition video first';
                      }
                      return null;
                    },
                    builder: (field) {
                      if (!field.hasError) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _soundFreeConfirmed,
                    onChanged: (value) {
                      setState(() {
                        _soundFreeConfirmed = value ?? false;
                      });
                    },
                    title: const Text('This video has no sound'),
                    subtitle: const Text(
                      'ABCDish will review it and prepare AI narration before recipe acceptance.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload),
                      label: const Text('Submit Entry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
