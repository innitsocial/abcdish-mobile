import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/contest.dart';
import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/providers/contest_provider.dart';
import 'package:abcdish/screens/contest_entry_form.dart';

class ContestsScreen extends ConsumerWidget {
  const ContestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestsProvider);

    return contestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                'Could not load contests. $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(contestsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (contests) {
        if (contests.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No cooking contests are open yet. New challenges will appear here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contests.length,
          itemBuilder: (context, index) =>
              _ContestCard(contest: contests[index]),
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
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contest.imageUrl.isNotEmpty)
            Image.network(
              contest.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contest.title,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Chip(label: Text(contest.status)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(contest.description),
                if (contest.prizeDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Prize: ${contest.prizeDescription}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                if (contest.endsAt != null) ...[
                  const SizedBox(height: 8),
                  Text('Ends: ${contest.endsAt!.toLocal()}'),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (!authState.isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please login to join contests'),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ContestEntryFormScreen(contest: contest),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Join Challenge'),
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
