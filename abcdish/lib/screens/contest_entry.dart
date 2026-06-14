import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/models/contest.dart';
import 'package:abcdish/services/contest_service.dart';
import 'package:abcdish/utils/auth_navigation.dart';

class ContestEntryScreen extends ConsumerStatefulWidget {
  const ContestEntryScreen({super.key, required this.contest});

  final Contest contest;

  @override
  ConsumerState<ContestEntryScreen> createState() => _ContestEntryScreenState();
}

class _ContestEntryScreenState extends ConsumerState<ContestEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _videoUrl = '';
  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final canContinue = await ensureLoggedIn(context, ref);
    if (!canContinue || !mounted) return;

    _formKey.currentState!.save();

    setState(() {
      _submitting = true;
    });

    try {
      final moderationStatus = await ContestService.instance.submitEntry(
        contestId: widget.contest.id,
        title: _title,
        videoUrl: _videoUrl,
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
      Navigator.of(context).pop();
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
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Video URL',
                      hintText: 'CloudFront/S3 video URL',
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a video URL';
                      }
                      return null;
                    },
                    onSaved: (value) => _videoUrl = value!.trim(),
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
