import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:abcdish/l10n/app_text.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/screens/login.dart';
import 'package:abcdish/services/api_client.dart';
import 'package:abcdish/services/meal_service.dart';
import 'package:abcdish/utils/error_messages.dart';

class CreatorUploadScreen extends ConsumerStatefulWidget {
  const CreatorUploadScreen({super.key, this.meal});

  final Meal? meal;

  @override
  ConsumerState<CreatorUploadScreen> createState() =>
      _CreatorUploadScreenState();
}

class _CreatorUploadScreenState extends ConsumerState<CreatorUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _videoUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _categoriesController = TextEditingController(text: 'cooking');
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promoTitleController = TextEditingController();
  final _promoSubtitleController = TextEditingController();
  String _title = '';
  String _description = '';
  String _imageUrl = '';
  String _videoUrl = '';
  String _trailerUrl = '';
  String _trailerType = 'PROMO_TEXT';
  String _promoTrailerTitle = '';
  String _promoTrailerSubtitle = '';
  String? _localTrailerPath;
  String? _localSourceVideoPath;
  String _complexity = Complexity.simple.name;
  bool _glutenFree = false;
  bool _lactoseFree = false;
  bool _vegan = false;
  bool _vegetarian = false;
  bool _isPublishing = false;
  bool _isExtractingDraft = false;

  bool get _isEditing => widget.meal != null;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    if (meal != null) {
      _titleController.text = meal.title;
      _descriptionController.text = meal.description;
      _videoUrlController.text = meal.videoUrl;
      _imageUrlController.text = meal.imageUrl;
      _trailerUrl = meal.trailerUrl;
      _trailerType = meal.trailerType.isEmpty ? 'VIDEO' : meal.trailerType;
      _promoTrailerTitle = meal.promoTrailerTitle;
      _promoTrailerSubtitle = meal.promoTrailerSubtitle;
      _promoTitleController.text = meal.promoTrailerTitle;
      _promoSubtitleController.text = meal.promoTrailerSubtitle;
      _durationController.text = meal.duration.toString();
      _categoriesController.text = meal.categories.join(', ');
      _ingredientsController.text = meal.ingredients.join('\n');
      _stepsController.text = meal.steps.join('\n');
      _complexity = meal.complexity.name;
      _glutenFree = meal.isGlutenFree;
      _lactoseFree = meal.isLactoseFree;
      _vegan = meal.isVegan;
      _vegetarian = meal.isVegetarian;
    }
    _videoUrlController.addListener(_refreshPreview);
    _imageUrlController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    _imageUrlController.dispose();
    _durationController.dispose();
    _categoriesController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _promoTitleController.dispose();
    _promoSubtitleController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  List<String> _splitList(String value) {
    return value
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _pickTrailer() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video == null || !mounted) return;

      setState(() {
        _localTrailerPath = video.path;
      });
    } catch (error) {
      if (!mounted) return;
      logUiError('Trailer picker failed', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyErrorMessage(
              error,
              fallback: ref
                  .read(appTextProvider)
                  .raw('Unable to choose trailer.'),
            ),
          ),
        ),
      );
    }
  }

  void _removeTrailer() {
    setState(() {
      _localTrailerPath = null;
      _trailerUrl = '';
    });
  }

  Future<void> _pickOwnVideoAndExtractDraft() async {
    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null || !mounted) return;

      setState(() {
        _isExtractingDraft = true;
        _localSourceVideoPath = video.path;
      });

      final videoUrl = await MealService.instance.uploadRecipeVideo(video.path);
      if (!mounted) return;

      _videoUrlController.text = videoUrl;
      await _extractDraft(sourceType: 'OWN_VIDEO', sourceUrl: videoUrl);
    } catch (error) {
      if (!mounted) return;
      if (await _redirectToLoginIfNeeded(error)) return;
      if (!mounted) return;

      logUiError('Video upload and draft extraction failed', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyErrorMessage(
              error,
              fallback: ref
                  .read(appTextProvider)
                  .raw('Unable to upload and read video.'),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingDraft = false;
        });
      }
    }
  }

  Future<void> _extractDraft({
    required String sourceType,
    required String sourceUrl,
  }) async {
    setState(() {
      _isExtractingDraft = true;
    });

    try {
      final draft = await MealService.instance.createDraft(
        sourceType: sourceType,
        sourceUrl: sourceUrl,
        titleHint: _titleController.text.trim(),
      );

      if (!mounted) return;
      _applyDraft(draft);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft['extractionMessage']?.toString() ??
                ref
                    .read(appTextProvider)
                    .raw('Draft created. Please verify before publishing.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      if (await _redirectToLoginIfNeeded(error)) return;
      if (!mounted) return;

      logUiError('Draft extraction failed', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyErrorMessage(
              error,
              fallback: ref.read(appTextProvider).raw('Unable to create draft'),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingDraft = false;
        });
      }
    }
  }

  void _applyDraft(Map<String, dynamic> draft) {
    String listText(String key) {
      final value = draft[key];
      if (value is List) {
        return value.map((item) => item.toString()).join('\n');
      }
      return value?.toString() ?? '';
    }

    setState(() {
      _titleController.text = draft['title']?.toString() ?? '';
      _descriptionController.text = draft['description']?.toString() ?? '';
      _imageUrlController.text = draft['imageUrl']?.toString() ?? '';
      _videoUrlController.text =
          draft['videoUrl']?.toString() ?? _videoUrlController.text;
      _trailerUrl = draft['trailerUrl']?.toString() ?? _trailerUrl;
      _trailerType = draft['trailerType']?.toString() ?? _trailerType;
      _promoTrailerTitle =
          draft['promoTrailerTitle']?.toString() ?? _promoTrailerTitle;
      _promoTrailerSubtitle =
          draft['promoTrailerSubtitle']?.toString() ?? _promoTrailerSubtitle;
      _promoTitleController.text = _promoTrailerTitle;
      _promoSubtitleController.text = _promoTrailerSubtitle;
      _durationController.text = (draft['duration'] ?? 30).toString();
      _complexity = draft['complexity']?.toString() ?? Complexity.simple.name;
      _categoriesController.text = listText(
        'categories',
      ).replaceAll('\n', ', ');
      _ingredientsController.text = listText('ingredients');
      _stepsController.text = listText('steps');
      _localTrailerPath = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_videoUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(appTextProvider).raw('Upload your cooking video first.'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      late final Meal meal;
      final resolvedTrailerUrl = _localTrailerPath == null
          ? _trailerUrl
          : await MealService.instance.uploadRecipeTrailer(_localTrailerPath!);
      final resolvedTrailerType = resolvedTrailerUrl.trim().isNotEmpty
          ? 'VIDEO'
          : 'PROMO_TEXT';
      final promoTitle = resolvedTrailerType == 'PROMO_TEXT'
          ? (_promoTitleController.text.trim().isEmpty
                ? _title
                : _promoTitleController.text.trim())
          : '';
      final promoSubtitle = resolvedTrailerType == 'PROMO_TEXT'
          ? (_promoSubtitleController.text.trim().isEmpty
                ? ref.read(appTextProvider).raw('Tap to cook the full recipe')
                : _promoSubtitleController.text.trim())
          : '';

      if (_isEditing) {
        meal = await MealService.instance.updateMeal(
          id: widget.meal!.id,
          title: _title,
          description: _description,
          imageUrl: _imageUrl,
          videoUrl: _videoUrl,
          trailerUrl: resolvedTrailerUrl,
          trailerType: resolvedTrailerType,
          promoTrailerTitle: promoTitle,
          promoTrailerSubtitle: promoSubtitle,
          duration: int.parse(_durationController.text.trim()),
          complexity: _complexity,
          affordability: widget.meal!.affordability.name,
          categories: _splitList(_categoriesController.text),
          ingredients: _splitList(_ingredientsController.text),
          steps: _splitList(_stepsController.text),
          glutenFree: _glutenFree,
          lactoseFree: _lactoseFree,
          vegan: _vegan,
          vegetarian: _vegetarian,
        );
      } else {
        meal = await MealService.instance.createMeal(
          title: _title,
          description: _description,
          imageUrl: _imageUrl,
          videoUrl: _videoUrl,
          trailerUrl: resolvedTrailerUrl,
          trailerType: resolvedTrailerType,
          promoTrailerTitle: promoTitle,
          promoTrailerSubtitle: promoSubtitle,
          duration: int.parse(_durationController.text.trim()),
          complexity: _complexity,
          affordability: Affordability.affordable.name,
          categories: _splitList(_categoriesController.text),
          ingredients: _splitList(_ingredientsController.text),
          steps: _splitList(_stepsController.text),
          glutenFree: _glutenFree,
          lactoseFree: _lactoseFree,
          vegan: _vegan,
          vegetarian: _vegetarian,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_successMessage(meal))));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      if (await _redirectToLoginIfNeeded(error)) return;
      if (!mounted) return;

      logUiError('Recipe publish failed', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyErrorMessage(
              error,
              fallback: ref
                  .read(appTextProvider)
                  .raw('Unable to publish recipe'),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  String _successMessage(Meal meal) {
    if (meal.moderationStatus == 'APPROVED') {
      return _isEditing
          ? '"$_title" has been updated and is live'
          : '"$_title" is published to the cooking feed';
    }

    if (meal.moderationStatus == 'REJECTED') {
      return '"$_title" was not published because it did not pass the safety check';
    }

    return '"$_title" was saved and is pending review';
  }

  Future<bool> _redirectToLoginIfNeeded(Object error) async {
    if (error is! ApiException ||
        (error.statusCode != 401 && error.statusCode != 403)) {
      return false;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _imageUrlController.text.trim();
    final text = ref.watch(appTextProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? text.raw('Edit Recipe') : text.addRecipe),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: previewUrl.isEmpty
                      ? Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.smart_display,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : Image.network(
                          previewUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.black,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.smart_display,
                                  color: Colors.white70,
                                  size: 64,
                                ),
                              ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                text.raw('Upload recipe'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                text.raw(
                  'Upload and manage ABCDish-owned cooking videos. No external video links.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _OwnVideoUploadPanel(
                videoUrl: _videoUrlController.text.trim(),
                hasLocalVideo: _localSourceVideoPath != null,
                extracting: _isExtractingDraft,
                onPickVideo: _pickOwnVideoAndExtractDraft,
              ),
              const SizedBox(height: 12),
              _TrailerPickerCard(
                hasLocalTrailer: _localTrailerPath != null,
                trailerUrl: _trailerUrl,
                requiredTrailer: true,
                onPickTrailer: _pickTrailer,
                onRemoveTrailer: _removeTrailer,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: text.raw('Title')),
                validator: (value) => value == null || value.trim().length < 3
                    ? text.raw('Enter title')
                    : null,
                onSaved: (value) => _title = value!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: text.raw('Description')),
                maxLines: 3,
                onSaved: (value) => _description = value?.trim() ?? '',
              ),
              FormField<String>(
                validator: (_) {
                  final videoUrl = _videoUrlController.text.trim();
                  if (videoUrl.isEmpty) {
                    return text.raw('Add a cooking video first');
                  }
                  return null;
                },
                onSaved: (_) => _videoUrl = _videoUrlController.text.trim(),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: text.raw('Cooking time'),
                  suffixText: 'min',
                  prefixIcon: const Icon(Icons.timer_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final duration = int.tryParse(value?.trim() ?? '');
                  if (duration == null || duration <= 0) {
                    return text.raw('Enter cooking time in minutes');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _complexity,
                decoration: InputDecoration(
                  labelText: text.raw('Difficulty'),
                  prefixIcon: const Icon(Icons.local_fire_department_outlined),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'simple',
                    child: Text(text.raw('Simple')),
                  ),
                  DropdownMenuItem(
                    value: 'challenging',
                    child: Text(text.raw('Medium')),
                  ),
                  DropdownMenuItem(
                    value: 'hard',
                    child: Text(text.raw('Difficult')),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _complexity = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    selected: _glutenFree,
                    label: Text(text.raw('Gluten-free')),
                    onSelected: (value) {
                      setState(() {
                        _glutenFree = value;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _lactoseFree,
                    label: Text(text.raw('Lactose-free')),
                    onSelected: (value) {
                      setState(() {
                        _lactoseFree = value;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _vegetarian,
                    label: Text(text.raw('Vegetarian')),
                    onSelected: (value) {
                      setState(() {
                        _vegetarian = value;
                      });
                    },
                  ),
                  FilterChip(
                    selected: _vegan,
                    label: Text(text.raw('Vegan')),
                    onSelected: (value) {
                      setState(() {
                        _vegan = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoriesController,
                decoration: InputDecoration(
                  labelText: text.raw('Categories'),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                validator: (value) => _splitList(value ?? '').isEmpty
                    ? text.raw('Enter at least one category')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ingredientsController,
                decoration: InputDecoration(
                  labelText: text.raw('Ingredients'),
                  prefixIcon: const Icon(Icons.format_list_bulleted),
                ),
                minLines: 3,
                maxLines: 6,
                validator: (value) => _splitList(value ?? '').isEmpty
                    ? text.raw('Enter at least one ingredient')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stepsController,
                decoration: InputDecoration(
                  labelText: text.raw('Cooking steps'),
                  prefixIcon: const Icon(Icons.checklist_outlined),
                ),
                minLines: 3,
                maxLines: 6,
                validator: (value) => _splitList(value ?? '').isEmpty
                    ? text.raw('Enter at least one cooking step')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: text.raw('Cover image URL'),
                  prefixIcon: const Icon(Icons.image_outlined),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSaved: (value) => _imageUrl = value?.trim() ?? '',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isPublishing ? null : _submit,
                  icon: _isPublishing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish),
                  label: Text(
                    _isPublishing
                        ? _isEditing
                              ? text.raw('Saving...')
                              : text.raw('Publishing...')
                        : _isEditing
                        ? text.raw('Save Changes')
                        : text.raw('Publish'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnVideoUploadPanel extends ConsumerWidget {
  const _OwnVideoUploadPanel({
    required this.videoUrl,
    required this.hasLocalVideo,
    required this.extracting,
    required this.onPickVideo,
  });

  final String videoUrl;
  final bool hasLocalVideo;
  final bool extracting;
  final VoidCallback onPickVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasVideo = videoUrl.isNotEmpty || hasLocalVideo;
    final text = ref.watch(appTextProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.video_file_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasVideo
                        ? text.raw('Cooking video uploaded')
                        : text.raw('Upload your cooking video'),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasVideo
                  ? text.raw(
                      'Review the extracted recipe details below before publishing.',
                    )
                  : text.raw(
                      'ABCDish will upload the video, create a draft, then ask you to verify it.',
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (videoUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                videoUrl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: extracting ? null : onPickVideo,
              icon: extracting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                extracting
                    ? text.raw('Uploading...')
                    : hasVideo
                    ? text.raw('Replace Video')
                    : text.raw('Upload Video & Extract'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailerPickerCard extends ConsumerWidget {
  const _TrailerPickerCard({
    required this.hasLocalTrailer,
    required this.trailerUrl,
    required this.requiredTrailer,
    required this.onPickTrailer,
    required this.onRemoveTrailer,
  });

  final bool hasLocalTrailer;
  final String trailerUrl;
  final bool requiredTrailer;
  final VoidCallback onPickTrailer;
  final VoidCallback onRemoveTrailer;

  bool get _hasTrailer => hasLocalTrailer || trailerUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = ref.watch(appTextProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.movie_creation_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text.raw('30 sec feed trailer'),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_hasTrailer)
                  IconButton(
                    onPressed: onRemoveTrailer,
                    icon: const Icon(Icons.close),
                    tooltip: text.raw('Remove trailer'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _hasTrailer
                  ? hasLocalTrailer
                        ? text.raw(
                            'New trailer selected. It will upload when you publish.',
                          )
                        : text.raw('Trailer attached for feed autoplay.')
                  : requiredTrailer
                  ? text.raw(
                      'Required for own videos until automatic trailer extraction is enabled.',
                    )
                  : text.raw(
                      'Optional. ABCDish can show a text promo until a trailer is ready.',
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPickTrailer,
                icon: const Icon(Icons.video_library_outlined),
                label: Text(
                  _hasTrailer
                      ? text.raw('Change Trailer')
                      : text.raw('Choose Trailer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
