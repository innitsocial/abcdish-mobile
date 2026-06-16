import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'package:abcdish/models/feed_comment.dart';
import 'package:abcdish/models/meal.dart';
import 'package:abcdish/models/story.dart';
import 'package:abcdish/providers/app_session_provider.dart';
import 'package:abcdish/providers/favorites_provider.dart';
import 'package:abcdish/providers/feed_provider.dart';
import 'package:abcdish/screens/create_story.dart';
import 'package:abcdish/screens/meal_details.dart';
import 'package:abcdish/services/contest_service.dart';
import 'package:abcdish/services/safety_service.dart';
import 'package:abcdish/services/social_service.dart';
import 'package:abcdish/services/story_service.dart';
import 'package:abcdish/utils/auth_navigation.dart';
import 'package:abcdish/utils/error_messages.dart';

class FoodFeedScreen extends ConsumerStatefulWidget {
  const FoodFeedScreen({super.key});

  @override
  ConsumerState<FoodFeedScreen> createState() => _FoodFeedScreenState();
}

class _FoodFeedScreenState extends ConsumerState<FoodFeedScreen> {
  static const _hiddenCreatorsKey = 'hidden_creator_keys';

  final List<Story> _stories = [];
  final Set<String> _hiddenCreatorKeys = {};
  late Future<void> _loadStoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadStoriesFuture = _loadStories();
    _loadHiddenCreators();
  }

  Future<void> _loadStories() async {
    final stories = await StoryService.instance.fetchStories();

    if (!mounted) return;

    setState(() {
      _stories
        ..clear()
        ..addAll(stories);
    });
  }

  Future<void> _loadHiddenCreators() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _hiddenCreatorKeys
        ..clear()
        ..addAll(prefs.getStringList(_hiddenCreatorsKey) ?? const []);
    });
  }

  void _openMeal(Meal meal) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => MealDetailsScreen(meal: meal)));
  }

  Future<void> _createStory() async {
    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !mounted) return;

    final story = await Navigator.of(context).push<Story>(
      MaterialPageRoute(builder: (context) => const CreateStoryScreen()),
    );

    if (story == null || !mounted) return;

    if (story.moderationStatus == 'APPROVED') {
      setState(() {
        _stories.insert(0, story);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          story.moderationStatus == 'APPROVED'
              ? 'Story posted'
              : 'Story saved and pending review',
        ),
      ),
    );
  }

  Future<void> _toggleLike(Meal meal) async {
    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue) return;

    try {
      if (meal.isContestEntry) {
        if (meal.likedByCurrentUser) {
          await ContestService.instance.unlikeEntry(meal.id);
        } else {
          await ContestService.instance.likeEntry(meal.id);
        }
      } else if (meal.likedByCurrentUser) {
        await SocialService.instance.unlikeMeal(meal.id);
      } else {
        await SocialService.instance.likeMeal(meal.id);
      }

      ref.invalidate(feedProvider);
    } catch (error) {
      await _showSocialError(error);
    }
  }

  Future<void> _toggleFollow(Meal meal) async {
    if (meal.isContestEntry) return;

    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue) return;

    try {
      if (meal.followedByCurrentUser) {
        await SocialService.instance.unfollowCreator(meal.creatorKey);
      } else {
        await SocialService.instance.followCreator(meal.creatorKey);
      }

      ref.invalidate(feedProvider);
    } catch (error) {
      await _showSocialError(error);
    }
  }

  Future<void> _shareMeal(Meal meal) async {
    if (meal.isContestEntry) return;

    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue) return;

    try {
      await SocialService.instance.shareMeal(meal.id);
      ref.invalidate(feedProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share link ready for ${meal.title}')),
      );
    } catch (error) {
      await _showSocialError(error);
    }
  }

  Future<void> _hideCreator(Meal meal) async {
    if (meal.isContestEntry) return;

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _hiddenCreatorKeys.add(meal.creatorKey);
    });

    await prefs.setStringList(_hiddenCreatorsKey, _hiddenCreatorKeys.toList());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hidden posts from ${_creatorName(meal)}')),
    );
  }

  Future<void> _reportMeal(Meal meal, String reason) async {
    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue) return;

    try {
      await SafetyService.instance.reportContent(
        targetType: 'meal',
        targetId: meal.id,
        reason: reason,
        details: meal.title,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks. We will review this post.')),
      );
    } catch (error) {
      await _showSocialError(error);
    }
  }

  void _showPostOptions(Meal meal) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(meal.isContestEntry ? 'Report entry' : 'Report post'),
              subtitle: const Text('Spam, unsafe, abusive, or inappropriate'),
              onTap: () {
                Navigator.of(context).pop();
                _showReportReasons(meal);
              },
            ),
            if (!meal.isContestEntry)
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text('Hide ${_creatorName(meal)}'),
                subtitle: const Text('Remove this creator from your feed'),
                onTap: () {
                  Navigator.of(context).pop();
                  _hideCreator(meal);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReportReasons(Meal meal) {
    const reasons = [
      'Spam or misleading',
      'Unsafe cooking advice',
      'Harassment or hate',
      'Adult or inappropriate content',
      'Copyright or stolen content',
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Why are you reporting this?',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final reason in reasons)
              ListTile(
                title: Text(reason),
                onTap: () {
                  Navigator.of(context).pop();
                  _reportMeal(meal, reason);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showStory(Meal meal) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _MealImage(meal: meal, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CreatorAvatar(name: _creatorName(meal)),
                        const SizedBox(width: 10),
                        Text(
                          _creatorName(meal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      meal.title,
                      style: Theme.of(context).textTheme.headlineSmall!
                          .copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meal.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openMeal(meal);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch & Cook'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _deleteStory(Story story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove story?'),
        content: Text('This removes "${story.title}" from ABCDish stories.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    try {
      await StoryService.instance.deleteStory(story.id);

      if (!mounted) return false;
      setState(() {
        _stories.removeWhere((item) => item.id == story.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Story removed')));
      return true;
    } catch (error) {
      if (!mounted) return false;
      final handled = await redirectToLoginForAuthError(context, ref, error);
      if (handled || !mounted) return false;

      logUiError('Story delete failed', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyErrorMessage(
              error,
              fallback: 'Unable to remove story. Please try again.',
            ),
          ),
        ),
      );
      return false;
    }
  }

  void _showUserStory(Story story) {
    final currentUserId = ref
        .read(appSessionProvider)
        .maybeWhen(data: (session) => session?.userId ?? 0, orElse: () => 0);
    final initialIndex = _stories.indexWhere((item) => item.id == story.id);

    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: _UserStoryViewer(
          stories: List<Story>.from(_stories),
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
          currentUserId: currentUserId,
          onDeleteStory: _deleteStory,
          onStoryChanged: (updatedStory) {
            if (!mounted) return;
            setState(() {
              final storyIndex = _stories.indexWhere(
                (item) => item.id == updatedStory.id,
              );
              if (storyIndex >= 0) {
                _stories[storyIndex] = updatedStory;
              }
            });
          },
        ),
      ),
    );
  }

  void _openComments(Meal meal) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CommentsSheet(
        meal: meal,
        onChanged: () => ref.invalidate(feedProvider),
        onAuthRequired: () => ensureLoggedIn(context, ref),
      ),
    );
  }

  Future<void> _showSocialError(Object error) async {
    if (!mounted) return;

    final handled = await redirectToLoginForAuthError(context, ref, error);
    if (handled || !mounted) return;

    logUiError('Feed social action failed', error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          userFriendlyErrorMessage(
            error,
            fallback: 'Could not complete this action. Please try again.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appSessionProvider);
    final feedAsync = ref.watch(feedProvider);

    return feedAsync.when(
      loading: () => const _FeedLoadingSkeleton(),
      error: (error, stackTrace) {
        logUiError('Feed load failed', error, stackTrace);
        return _FeedMessage(
          title: 'Unable to load feed',
          message: userFriendlyErrorMessage(
            error,
            fallback: 'The cooking feed is not available right now.',
          ),
          onRetry: () => ref.invalidate(feedProvider),
        );
      },
      data: (meals) {
        final visibleMeals = meals
            .where((meal) => !_hiddenCreatorKeys.contains(meal.creatorKey))
            .toList();

        if (visibleMeals.isEmpty) {
          return _FeedMessage(
            title: 'Food feed is warming up',
            message: meals.isEmpty
                ? 'Recipes and creator videos will appear here.'
                : 'You have hidden all available creator posts.',
            onRetry: () => ref.invalidate(feedProvider),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.refresh(feedProvider.future),
              _loadStories(),
            ]);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _FeedHeader(
                  postCount: meals.length,
                  onRefresh: () => ref.invalidate(feedProvider),
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<void>(
                  future: _loadStoriesFuture,
                  builder: (context, snapshot) => _StoriesStrip(
                    meals: meals,
                    userStories: _stories,
                    onCreateStory: _createStory,
                    onStoryTap: _showStory,
                    onUserStoryTap: _showUserStory,
                  ),
                ),
              ),
              SliverList.separated(
                itemCount: visibleMeals.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final meal = visibleMeals[index];

                  return _SocialMealPost(
                    meal: meal,
                    creatorName: _creatorName(meal),
                    isLiked: meal.likedByCurrentUser,
                    isFollowing: meal.followedByCurrentUser,
                    likeCount: meal.likeCount,
                    commentCount: meal.commentCount,
                    shareCount: meal.shareCount,
                    onOpenMeal: () => _openMeal(meal),
                    onLike: () => _toggleLike(meal),
                    onComment: meal.isContestEntry
                        ? () {}
                        : () => _openComments(meal),
                    onShare: meal.isContestEntry
                        ? () {}
                        : () => _shareMeal(meal),
                    onFollow: () => _toggleFollow(meal),
                    onMoreOptions: () => _showPostOptions(meal),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
            ],
          ),
        );
      },
    );
  }
}

class _UserStoryViewer extends StatefulWidget {
  const _UserStoryViewer({
    required this.stories,
    required this.initialIndex,
    required this.currentUserId,
    required this.onDeleteStory,
    required this.onStoryChanged,
  });

  final List<Story> stories;
  final int initialIndex;
  final int currentUserId;
  final Future<bool> Function(Story story) onDeleteStory;
  final void Function(Story story) onStoryChanged;

  @override
  State<_UserStoryViewer> createState() => _UserStoryViewerState();
}

class _UserStoryViewerState extends State<_UserStoryViewer> {
  static const _storyDuration = Duration(seconds: 7);
  static const _tickDuration = Duration(milliseconds: 80);

  late final List<Story> _stories;
  late int _index;
  Timer? _timer;
  double _progress = 0;
  bool _paused = false;
  final Set<String> _viewedStoryIds = {};

  Story get _story => _stories[_index];

  bool get _isOwnStory =>
      _story.userId != 0 && _story.userId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _stories = List<Story>.from(widget.stories);
    _index = widget.initialIndex.clamp(0, _stories.length - 1).toInt();
    _recordView();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickDuration, (_) {
      if (!mounted || _paused) return;

      setState(() {
        _progress +=
            _tickDuration.inMilliseconds / _storyDuration.inMilliseconds;
      });

      if (_progress >= 1) {
        _nextStory();
      }
    });
  }

  void _recordView() {
    if (widget.currentUserId == 0 || _viewedStoryIds.contains(_story.id)) {
      return;
    }

    _viewedStoryIds.add(_story.id);
    StoryService.instance.recordView(_story.id).then(_replaceStory).catchError((
      error,
    ) {
      debugPrint('Story view tracking failed: $error');
    });
  }

  void _replaceStory(Story story) {
    if (!mounted) return;

    setState(() {
      final storyIndex = _stories.indexWhere((item) => item.id == story.id);
      if (storyIndex >= 0) {
        _stories[storyIndex] = story;
      }
    });

    widget.onStoryChanged(story);
  }

  void _nextStory() {
    if (_index >= _stories.length - 1) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _index += 1;
      _progress = 0;
    });
    _recordView();
  }

  void _previousStory() {
    if (_index == 0) {
      setState(() => _progress = 0);
      return;
    }

    setState(() {
      _index -= 1;
      _progress = 0;
    });
    _recordView();
  }

  Future<void> _toggleLike() async {
    if (widget.currentUserId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Log in to like stories')));
      return;
    }

    final current = _story;
    final optimistic = current.copyWith(
      likedByCurrentUser: !current.likedByCurrentUser,
      likeCount: (current.likeCount + (current.likedByCurrentUser ? -1 : 1))
          .clamp(0, 1 << 31)
          .toInt(),
    );
    _replaceStory(optimistic);

    try {
      final updated = current.likedByCurrentUser
          ? await StoryService.instance.unlikeStory(current.id)
          : await StoryService.instance.likeStory(current.id);
      _replaceStory(updated);
    } catch (error) {
      _replaceStory(current);
      if (!mounted) return;
      logUiError('Story like update failed', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyErrorMessage(
              error,
              fallback: 'Could not update story like. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteCurrentStory() async {
    final removed = await widget.onDeleteStory(_story);
    if (!removed || !mounted) return;

    _stories.removeAt(_index);
    if (_stories.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      if (_index >= _stories.length) {
        _index = _stories.length - 1;
      }
      _progress = 0;
    });
  }

  void _showViewers() {
    setState(() => _paused = true);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _StoryViewersSheet(story: _story),
    ).whenComplete(() {
      if (mounted) setState(() => _paused = false);
    });
  }

  void _handleTap(TapUpDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    if (details.localPosition.dx < width * 0.35) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _handleTap,
      onLongPressStart: (_) => setState(() => _paused = true),
      onLongPressEnd: (_) => setState(() => _paused = false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _StoryFullVideo(key: ValueKey(story.id), story: story),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StoryProgressBars(
                    count: _stories.length,
                    activeIndex: _index,
                    activeProgress: _progress.clamp(0, 1),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _CreatorAvatar(name: story.creatorName),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              story.creatorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_relativeTime(story.createdAt)} ago',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.74),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isOwnStory)
                        IconButton(
                          onPressed: _deleteCurrentStory,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                          tooltip: 'Remove story',
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (story.caption.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      story.caption,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                  if (story.contestEntryId != null) ...[
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                story.promotedVideoTitle.isEmpty
                                    ? 'Contest video'
                                    : story.promotedVideoTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      IconButton.filled(
                        onPressed: _toggleLike,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          foregroundColor: story.likedByCurrentUser
                              ? Colors.pinkAccent
                              : Colors.white,
                        ),
                        icon: Icon(
                          story.likedByCurrentUser
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        tooltip: 'Like story',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _compactCount(story.likeCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (_isOwnStory)
                        TextButton.icon(
                          onPressed: _showViewers,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                          ),
                          icon: const Icon(Icons.visibility_outlined),
                          label: Text(_compactCount(story.viewCount)),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.78),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _compactCount(story.viewCount),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_paused)
            const Center(
              child: Icon(Icons.pause_circle, color: Colors.white70, size: 72),
            ),
        ],
      ),
    );
  }
}

class _StoryProgressBars extends StatelessWidget {
  const _StoryProgressBars({
    required this.count,
    required this.activeIndex,
    required this.activeProgress,
  });

  final int count;
  final int activeIndex;
  final double activeProgress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final value = index < activeIndex
            ? 1.0
            : index == activeIndex
            ? activeProgress
            : 0.0;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == count - 1 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.26),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StoryViewersSheet extends StatelessWidget {
  const _StoryViewersSheet({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<StoryViewer>>(
        future: StoryService.instance.fetchViewers(story.id),
        builder: (context, snapshot) {
          final viewers = snapshot.data ?? const <StoryViewer>[];

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Story viewers',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_compactCount(story.viewCount)} views',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      userFriendlyErrorMessage(
                        snapshot.error!,
                        fallback: 'Could not load viewers. Please try again.',
                      ),
                    ),
                  )
                else if (viewers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No one has viewed this story yet.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: viewers.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final viewer = viewers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _CreatorAvatar(name: viewer.name),
                          title: Text(viewer.name),
                          subtitle: Text(
                            'Viewed ${_relativeTime(viewer.viewedAt)} ago',
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StoriesStrip extends StatelessWidget {
  const _StoriesStrip({
    required this.meals,
    required this.userStories,
    required this.onCreateStory,
    required this.onStoryTap,
    required this.onUserStoryTap,
  });

  final List<Meal> meals;
  final List<Story> userStories;
  final VoidCallback onCreateStory;
  final void Function(Meal meal) onStoryTap;
  final void Function(Story story) onUserStoryTap;

  @override
  Widget build(BuildContext context) {
    final storyMeals = meals.take(8).toList();
    final totalStories = storyMeals.length + userStories.length;

    return SizedBox(
      height: 136,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        scrollDirection: Axis.horizontal,
        itemCount: totalStories + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CreateStoryCard(onTap: onCreateStory);
          }

          final storyIndex = index - 1;

          if (storyIndex < userStories.length) {
            final story = userStories[storyIndex];
            return _UserStoryCard(
              story: story,
              onTap: () => onUserStoryTap(story),
            );
          }

          final meal = storyMeals[storyIndex - userStories.length];
          return _StoryCard(meal: meal, onTap: () => onStoryTap(meal));
        },
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.postCount, required this.onRefresh});

  final int postCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For you',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '$postCount cooking videos and recipes',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh feed',
          ),
        ],
      ),
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create story',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserStoryCard extends StatelessWidget {
  const _UserStoryCard({required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _StoryPreview(story: story),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: _CreatorAvatar(name: story.creatorName, size: 30),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.meal, required this.onTap});

  final Meal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MealImage(meal: meal, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: _CreatorAvatar(name: _creatorName(meal), size: 30),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  meal.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

class _SocialMealPost extends ConsumerStatefulWidget {
  const _SocialMealPost({
    required this.meal,
    required this.creatorName,
    required this.isLiked,
    required this.isFollowing,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.onOpenMeal,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onFollow,
    required this.onMoreOptions,
  });

  final Meal meal;
  final String creatorName;
  final bool isLiked;
  final bool isFollowing;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final VoidCallback onOpenMeal;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onFollow;
  final VoidCallback onMoreOptions;

  @override
  ConsumerState<_SocialMealPost> createState() => _SocialMealPostState();
}

class _SocialMealPostState extends ConsumerState<_SocialMealPost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _likeBurstController;
  late final Animation<double> _likeBurstScale;
  late final Animation<double> _likeBurstOpacity;

  @override
  void initState() {
    super.initState();
    _likeBurstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _likeBurstScale = Tween<double>(begin: 0.35, end: 1.12).animate(
      CurvedAnimation(
        parent: _likeBurstController,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _likeBurstOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 25),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 40),
    ]).animate(_likeBurstController);
  }

  @override
  void dispose() {
    _likeBurstController.dispose();
    super.dispose();
  }

  void _handleDoubleTapLike() {
    _likeBurstController.forward(from: 0);
    if (!widget.isLiked) {
      widget.onLike();
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final favoriteMeals = ref.watch(favoriteMealsProvider);
    final isSaved = favoriteMeals.any((item) => item.id == meal.id);
    final colorScheme = Theme.of(context).colorScheme;
    final caption = meal.description.trim().isEmpty
        ? meal.isContestEntry
              ? 'Vote for recipe clarity, cooking method, and final dish.'
              : 'Fresh cooking inspiration from ABCDish.'
        : meal.description.trim();
    final isContestEntry = meal.isContestEntry;
    final threshold = meal.acceptanceThreshold <= 0
        ? 500
        : meal.acceptanceThreshold;
    final progress = (widget.likeCount / threshold).clamp(0.0, 1.0);
    final contestStageLabel = meal.competitionStatus == 'WINNER'
        ? 'Category winner • £${_compactCount(meal.prizeAmountGbp ?? 100000)}'
        : meal.londonQualified
        ? 'Top 100 London finalist'
        : 'Public voting';
    final contestChipLabel = meal.competitionStatus == 'WINNER'
        ? 'Winner'
        : meal.londonQualified
        ? '#${meal.finalistRank ?? ''} London'.trim()
        : 'Vote';
    final trailerUrl = meal.trailerUrl.trim();
    final videoUrl = meal.videoUrl.trim();
    final sourceLabel = isContestEntry
        ? _categoryLabel(meal.competitionCategory)
        : trailerUrl.isNotEmpty
        ? '30 sec trailer'
        : videoUrl.isEmpty
        ? null
        : 'ABCDish video';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.hardEdge,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isContestEntry
            ? BorderSide(color: colorScheme.primary, width: 1.4)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                _CreatorAvatar(
                  name: isContestEntry
                      ? 'ABCDish Challenge'
                      : widget.creatorName,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isContestEntry
                            ? 'ABCDish Challenge'
                            : widget.creatorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isContestEntry
                            ? contestStageLabel
                            : '${meal.duration} min recipe • ${meal.complexity.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isContestEntry)
                  Chip(
                    avatar: const Icon(Icons.emoji_events_outlined, size: 16),
                    label: Text(contestChipLabel),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  TextButton.icon(
                    onPressed: widget.onFollow,
                    icon: Icon(
                      widget.isFollowing ? Icons.check : Icons.person_add_alt_1,
                      size: 16,
                    ),
                    label: Text(widget.isFollowing ? 'Following' : 'Follow'),
                  ),
                IconButton(
                  onPressed: widget.onMoreOptions,
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'Post options',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: _PostCaption(title: meal.title, caption: caption),
          ),
          GestureDetector(
            onTap: widget.onOpenMeal,
            onDoubleTap: _handleDoubleTapLike,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _MealPreview(meal: meal),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _InfoPill(
                      icon: Icons.timer_outlined,
                      label: '${meal.duration} min',
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _InfoPill(
                      icon: isContestEntry
                          ? Icons.how_to_vote_outlined
                          : Icons.restaurant_menu,
                      label: isContestEntry ? 'Contest' : meal.complexity.name,
                    ),
                  ),
                  if (sourceLabel != null)
                    Positioned(
                      left: 12,
                      top: 54,
                      child: _VideoSourcePill(label: sourceLabel),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 76,
                    child: isContestEntry
                        ? _ContestProgressCta(
                            votes: widget.likeCount,
                            threshold: threshold,
                            progress: progress,
                            statusLabel: contestStageLabel,
                            isWinner: meal.competitionStatus == 'WINNER',
                            onVote: widget.onLike,
                          )
                        : _OpenRecipeCta(onTap: widget.onOpenMeal),
                  ),
                  Center(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _likeBurstController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _likeBurstOpacity.value,
                            child: Transform.scale(
                              scale: _likeBurstScale.value,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 108,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              meal.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                _MetricPill(
                  icon: Icons.favorite,
                  label: _compactCount(widget.likeCount),
                  color: widget.isLiked
                      ? Colors.redAccent
                      : colorScheme.primary,
                ),
                const Spacer(),
                if (isContestEntry)
                  Text(
                    contestStageLabel,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else ...[
                  TextButton(
                    onPressed: widget.onComment,
                    child: Text(
                      '${_compactCount(widget.commentCount)} comments',
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onShare,
                    child: Text('${_compactCount(widget.shareCount)} shares'),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: _PostActionButton(
                    icon: widget.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: isContestEntry ? 'Vote' : 'Like',
                    color: widget.isLiked ? Colors.redAccent : null,
                    onPressed: widget.onLike,
                  ),
                ),
                if (!isContestEntry) ...[
                  Expanded(
                    child: _PostActionButton(
                      icon: Icons.mode_comment_outlined,
                      label: 'Comment',
                      onPressed: widget.onComment,
                    ),
                  ),
                  Expanded(
                    child: _PostActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onPressed: widget.onShare,
                    ),
                  ),
                  Expanded(
                    child: _PostActionButton(
                      icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                      label: 'Save',
                      color: isSaved ? colorScheme.primary : null,
                      onPressed: () async {
                        final canContinue = await ensureLoggedIn(context, ref);
                        if (!canContinue || !context.mounted) return;

                        ref
                            .read(favoriteMealsProvider.notifier)
                            .toggleMealFavoriteStatus(meal);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    final cleaned = category.trim().replaceAll('_', ' ');
    if (cleaned.isEmpty || cleaned == 'main') {
      return 'Competition entry';
    }
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
  }
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

class _PostCaption extends StatefulWidget {
  const _PostCaption({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  State<_PostCaption> createState() => _PostCaptionState();
}

class _PostCaptionState extends State<_PostCaption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: widget.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '  '),
              TextSpan(text: widget.caption),
            ],
          ),
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (widget.caption.length > 120)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.only(top: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            child: Text(_expanded ? 'Show less' : 'Read more'),
          ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.meal,
    required this.onChanged,
    required this.onAuthRequired,
  });

  final Meal meal;
  final VoidCallback onChanged;
  final Future<bool> Function() onAuthRequired;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  late Future<void> _loadCommentsFuture;
  List<FeedComment> _comments = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCommentsFuture = _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final comments = await SocialService.instance.fetchComments(widget.meal.id);

    if (!mounted) return;

    setState(() {
      _comments = comments;
    });
  }

  Future<void> _addComment() async {
    final comment = _controller.text.trim();
    if (comment.isEmpty) return;

    final canContinue = await widget.onAuthRequired();
    if (!canContinue || !mounted) return;

    setState(() {
      _submitting = true;
    });

    try {
      final savedComment = await SocialService.instance.addComment(
        widget.meal.id,
        comment,
      );

      if (!mounted) return;

      setState(() {
        _comments.insert(0, savedComment);
        _controller.clear();
      });
      widget.onChanged();
    } catch (error) {
      if (!mounted) return;
      if (isAuthError(error)) {
        await widget.onAuthRequired();
        return;
      }
      logUiError('Comment submit failed', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFriendlyErrorMessage(
              error,
              fallback: 'Could not add comment. Please try again.',
            ),
          ),
        ),
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.meal.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<void>(
              future: _loadCommentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (_comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No comments yet. Start the conversation.'),
                  );
                }

                return SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.36,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _comments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _CommentTile(comment: _comments[index]),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _submitting ? null : _addComment,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final FeedComment comment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          child: Text('${comment.userId == 0 ? 'A' : comment.userId}'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.userId == 0
                              ? 'ABCDish cook'
                              : 'Cook ${comment.userId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium!
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (comment.createdAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(comment.createdAt!),
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(comment.text),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealPreview extends StatelessWidget {
  const _MealPreview({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final trailerUrl = meal.trailerUrl.trim();
    final videoUrl = trailerUrl.isNotEmpty ? trailerUrl : meal.videoUrl.trim();

    if (videoUrl.isEmpty) {
      if (meal.trailerType == 'PROMO_TEXT') {
        return _PromoTextTrailer(meal: meal);
      }
      return _MealImage(meal: meal, fit: BoxFit.cover);
    }

    if (trailerUrl.isNotEmpty) {
      return _AutoPlayVideoPreview(
        videoUrl: trailerUrl,
        fallback: _MealImage(meal: meal, fit: BoxFit.cover),
      );
    }

    return _AutoPlayVideoPreview(
      videoUrl: videoUrl,
      fallback: _MealImage(meal: meal, fit: BoxFit.cover),
    );
  }
}

class _PromoTextTrailer extends StatelessWidget {
  const _PromoTextTrailer({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final title = meal.promoTrailerTitle.trim().isNotEmpty
        ? meal.promoTrailerTitle.trim()
        : meal.title;
    final subtitle = meal.promoTrailerSubtitle.trim().isNotEmpty
        ? meal.promoTrailerSubtitle.trim()
        : 'Watch the recipe and cook along on ABCDish.';

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE94335), Color(0xFF2E7D32)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          meal.creatorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium!
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenRecipeCta extends StatefulWidget {
  const _OpenRecipeCta({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_OpenRecipeCta> createState() => _OpenRecipeCtaState();
}

class _OpenRecipeCtaState extends State<_OpenRecipeCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.98,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(
      begin: 0.84,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: FilledButton.icon(
            onPressed: widget.onTap,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Want to cook?'),
          ),
        ),
      ),
    );
  }
}

class _ContestProgressCta extends StatelessWidget {
  const _ContestProgressCta({
    required this.votes,
    required this.threshold,
    required this.progress,
    required this.statusLabel,
    required this.isWinner,
    required this.onVote,
  });

  final int votes;
  final int threshold;
  final double progress;
  final String statusLabel;
  final bool isWinner;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onVote,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWinner
                            ? Icons.workspace_premium_outlined
                            : Icons.how_to_vote_outlined,
                        color: Colors.black87,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.black12,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$votes / $threshold recipe-first votes',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Colors.black.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
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

class _VideoSourcePill extends StatelessWidget {
  const _VideoSourcePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, color: Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPreview extends StatelessWidget {
  const _StoryPreview({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final videoUrl = story.videoUrl.trim();

    if (videoUrl.isEmpty) {
      return _StoryImage(story: story, fit: BoxFit.cover);
    }

    return _AutoPlayVideoPreview(
      videoUrl: videoUrl,
      fallback: _StoryImage(story: story, fit: BoxFit.cover),
    );
  }
}

class _AutoPlayVideoPreview extends StatefulWidget {
  const _AutoPlayVideoPreview({required this.videoUrl, required this.fallback});

  final String videoUrl;
  final Widget fallback;

  @override
  State<_AutoPlayVideoPreview> createState() => _AutoPlayVideoPreviewState();
}

class _AutoPlayVideoPreviewState extends State<_AutoPlayVideoPreview> {
  static const Duration _previewDuration = Duration(seconds: 25);

  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant _AutoPlayVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _setupController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _setupController() async {
    setState(() {
      _hasError = false;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(false);

      controller.addListener(_pauseAtPreviewLimit);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });

      await controller.play();
    } catch (error) {
      debugPrint('Video preview error: $error');
      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  void _pauseAtPreviewLimit() {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.position >= _previewDuration &&
        controller.value.isPlaying) {
      controller.pause();
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    controller?.removeListener(_pauseAtPreviewLimit);
    await controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_hasError || controller == null || !controller.value.isInitialized) {
      return widget.fallback;
    }

    final size = controller.value.size;

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_off, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Preview',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryFullVideo extends StatefulWidget {
  const _StoryFullVideo({super.key, required this.story});

  final Story story;

  @override
  State<_StoryFullVideo> createState() => _StoryFullVideoState();
}

class _StoryFullVideoState extends State<_StoryFullVideo> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _setupVideo();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _setupVideo() async {
    final videoUrl = widget.story.videoUrl.trim();
    if (videoUrl.isEmpty) return;

    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        allowMuting: true,
        showControls: true,
        aspectRatio: controller.value.aspectRatio,
      );

      setState(() {
        _videoController = controller;
        _chewieController = chewieController;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Story full video error: $error');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;
    final videoController = _videoController;

    if (chewieController != null && videoController != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: AspectRatio(
          aspectRatio: videoController.value.aspectRatio,
          child: Chewie(controller: chewieController),
        ),
      );
    }

    if (_loading) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_failed) {
      return _StoryImage(story: widget.story, fit: BoxFit.cover);
    }

    return _StoryImage(story: widget.story, fit: BoxFit.cover);
  }
}

class _MealImage extends StatelessWidget {
  const _MealImage({required this.meal, required this.fit});

  final Meal meal;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (meal.imageUrl.trim().isEmpty) {
      return _ImageFallback();
    }

    return Image.network(
      meal.imageUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _ImageFallback(),
    );
  }
}

class _StoryImage extends StatelessWidget {
  const _StoryImage({required this.story, required this.fit});

  final Story story;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (story.imageUrl.trim().isEmpty) {
      return _StoryFallback(story: story);
    }

    return Image.network(
      story.imageUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          _StoryFallback(story: story),
    );
  }
}

class _StoryFallback extends StatelessWidget {
  const _StoryFallback({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Text(
        story.title,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_menu, color: Colors.white70, size: 72),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dynamic_feed, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedLoadingSkeleton extends StatelessWidget {
  const _FeedLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _SkeletonLine(width: 140, height: 24, color: colorScheme),
        const SizedBox(height: 10),
        _SkeletonLine(width: 220, height: 14, color: colorScheme),
        const SizedBox(height: 18),
        SizedBox(
          height: 112,
          child: Row(
            children: List.generate(
              4,
              (index) => Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 10),
                child: _SkeletonLine(
                  width: 84,
                  height: 112,
                  color: colorScheme,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < 2; index++) ...[
          _SkeletonPost(colorScheme: colorScheme),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _SkeletonPost extends StatelessWidget {
  const _SkeletonPost({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SkeletonLine(width: 40, height: 40, color: colorScheme),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(width: 150, height: 14, color: colorScheme),
                    const SizedBox(height: 7),
                    _SkeletonLine(width: 100, height: 12, color: colorScheme),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SkeletonLine(
              width: double.infinity,
              height: 320,
              color: colorScheme,
            ),
            const SizedBox(height: 12),
            _SkeletonLine(width: 230, height: 16, color: colorScheme),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

String _creatorName(Meal meal) {
  if (meal.creatorName.trim().isNotEmpty) {
    return meal.creatorName;
  }

  final source = meal.categories.isEmpty ? meal.id : meal.categories.first;
  final cleaned = source.replaceAll('-', ' ').trim();
  if (cleaned.isEmpty) {
    return 'ABCDish Creator';
  }

  return '${cleaned[0].toUpperCase()}${cleaned.substring(1)} Kitchen';
}

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${_compactDecimal(value / 1000000, value >= 10000000)}M';
  }

  if (value >= 1000) {
    return '${_compactDecimal(value / 1000, value >= 10000)}K';
  }

  return value.toString();
}

String _compactDecimal(double value, bool wholeNumber) {
  final formatted = value.toStringAsFixed(wholeNumber ? 0 : 1);
  return formatted.endsWith('.0')
      ? formatted.substring(0, formatted.length - 2)
      : formatted;
}

String _relativeTime(DateTime createdAt) {
  final difference = DateTime.now().difference(createdAt);

  if (difference.inDays >= 1) {
    return '${difference.inDays}d';
  }

  if (difference.inHours >= 1) {
    return '${difference.inHours}h';
  }

  if (difference.inMinutes >= 1) {
    return '${difference.inMinutes}m';
  }

  return 'now';
}
