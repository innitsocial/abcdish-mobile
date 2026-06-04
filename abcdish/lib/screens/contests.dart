import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/contest.dart';
import 'package:abcdish/providers/contest_provider.dart';
import 'package:abcdish/screens/contest_entry.dart';

class ContestsScreen extends ConsumerWidget {
  const ContestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestsProvider);

    return contestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ContestEmpty(
        title: 'Unable to load contests',
        message: '$error',
        onRetry: () => ref.invalidate(contestsProvider),
      ),
      data: (contests) {
        if (contests.isEmpty) {
          return _ContestEmpty(
            title: 'Cooking challenges coming soon',
            message:
                'ABCDish contests will let users upload cooking videos, vote and win prizes.',
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

class _ContestCard extends StatelessWidget {
  const _ContestCard({required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                'Prize: ${contest.prize}',
                style: TextStyle(color: colorScheme.primary),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => ContestEntryScreen(contest: contest),
                  ),
                );
              },
              icon: const Icon(Icons.video_call),
              label: const Text('Submit Entry'),
            ),
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
            const Icon(Icons.emoji_events_outlined, size: 64),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
