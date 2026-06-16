import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/l10n/app_text.dart';
import 'package:abcdish/models/contest.dart';
import 'package:abcdish/models/contest_entry.dart';
import 'package:abcdish/providers/app_session_provider.dart';
import 'package:abcdish/providers/contest_provider.dart';
import 'package:abcdish/screens/contest_entry.dart';
import 'package:abcdish/screens/create_story.dart';
import 'package:abcdish/services/contest_service.dart';
import 'package:abcdish/utils/app_snack_bar.dart';
import 'package:abcdish/utils/auth_navigation.dart';
import 'package:abcdish/utils/error_messages.dart';

class ContestsScreen extends ConsumerWidget {
  const ContestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestsProvider);
    final text = ref.watch(appTextProvider);

    return contestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        logUiError('Contests load failed', error, stackTrace);
        return _ContestEmpty(
          title: text.raw('Unable to load contests'),
          message: userFriendlyErrorMessage(
            error,
            fallback: 'Cooking contests are not available right now.',
          ),
          refreshLabel: text.raw('Refresh'),
          onRetry: () => ref.invalidate(contestsProvider),
        );
      },
      data: (contests) {
        if (contests.isEmpty) {
          return _ContestEmpty(
            title: text.raw('Cooking challenges coming soon'),
            message: text.raw(
              'ABCDish contests will let users upload cooking videos, vote and win prizes.',
            ),
            refreshLabel: text.raw('Refresh'),
            onRetry: () => ref.invalidate(contestsProvider),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contests.length,
          itemBuilder: (context, index) {
            return _ContestCard(contest: contests[index]);
          },
        );
      },
    );
  }
}

class _ContestCard extends ConsumerWidget {
  const _ContestCard({required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = ref.watch(appTextProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(contest.status),
              backgroundColor: colorScheme.primaryContainer,
            ),
            const SizedBox(height: 10),
            Text(
              contest.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(contest.description),
            if (contest.prize != null && contest.prize!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${text.raw('Prize')}: ${contest.prize}',
                style: TextStyle(color: colorScheme.primary),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final published = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (ctx) => ContestEntryScreen(contest: contest),
                  ),
                );
                if (published == true) {
                  ref.invalidate(contestEntriesProvider(contest.id));
                }
              },
              icon: const Icon(Icons.video_call),
              label: Text(text.raw('Submit Entry')),
            ),
            const SizedBox(height: 16),
            _ContestEntries(contestId: contest.id),
          ],
        ),
      ),
    );
  }
}

class _ContestEntries extends ConsumerWidget {
  const _ContestEntries({required this.contestId});

  final String contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(contestEntriesProvider(contestId));

    return entriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) {
        logUiError('Contest entries load failed', error, stackTrace);
        return Text(
          userFriendlyErrorMessage(
            error,
            fallback: 'Could not load entries. Please try again.',
          ),
        );
      },
      data: (entries) {
        if (entries.isEmpty) {
          return Text(
            'No entries yet. Be the first cook in this challenge.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        return Column(
          children: [
            for (final entry in entries)
              _ContestEntryTile(
                entry: entry,
                onChanged: () =>
                    ref.invalidate(contestEntriesProvider(contestId)),
              ),
          ],
        );
      },
    );
  }
}

class _ContestEntryTile extends ConsumerWidget {
  const _ContestEntryTile({required this.entry, required this.onChanged});

  final ContestEntry entry;
  final VoidCallback onChanged;

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !context.mounted) return;

    try {
      if (entry.likedByCurrentUser) {
        await ContestService.instance.unlikeEntry(entry.id);
      } else {
        await ContestService.instance.likeEntry(entry.id);
      }
      onChanged();
    } catch (error) {
      if (!context.mounted) return;
      final handled = await redirectToLoginForAuthError(context, ref, error);
      if (handled || !context.mounted) return;

      logUiError('Contest vote update failed', error);
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(
          userFriendlyErrorMessage(
            error,
            fallback: 'Could not update vote. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _promoteWithStory(BuildContext context, WidgetRef ref) async {
    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateStoryScreen(promotedEntry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = ref.watch(appSessionProvider).asData?.value;
    final isOwnEntry = session != null && session.userId == entry.userId;
    final threshold = entry.acceptanceThreshold <= 0
        ? 500
        : entry.acceptanceThreshold;
    final progress = (entry.votes / threshold).clamp(0.0, 1.0);
    final readyForAdminReview = !entry.approved && entry.votes >= threshold;
    final likesAway = (threshold - entry.votes).clamp(0, threshold);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    entry.approved ? Icons.verified : Icons.restaurant_menu,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        entry.approved
                            ? 'Accepted into ABCDish recipes'
                            : readyForAdminReview
                            ? 'Ready for admin review'
                            : '$likesAway likes away from review',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleLike(context, ref),
                  icon: Icon(
                    entry.likedByCurrentUser
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: entry.likedByCurrentUser ? Colors.redAccent : null,
                  ),
                ),
              ],
            ),
            if (entry.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 6),
            Text(
              '${entry.votes} / $threshold review unlock likes',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isOwnEntry) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _promoteWithStory(context, ref),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Promote with story'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContestEmpty extends StatelessWidget {
  const _ContestEmpty({
    required this.title,
    required this.message,
    required this.refreshLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String refreshLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 64),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(refreshLabel),
            ),
          ],
        ),
      ),
    );
  }
}
