import 'package:flutter/material.dart';

import 'package:abcdish/models/contest.dart';
import 'package:abcdish/services/contest_service.dart';

class ContestEntryFormScreen extends StatefulWidget {
  const ContestEntryFormScreen({super.key, required this.contest});

  final Contest contest;

  @override
  State<ContestEntryFormScreen> createState() => _ContestEntryFormScreenState();
}

class _ContestEntryFormScreenState extends State<ContestEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  String _videoUrl = '';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      await ContestService.instance.joinContest(
        contestId: widget.contest.id,
        title: _title,
        description: _description,
        videoUrl: _videoUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contest entry submitted for review')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not submit entry: $error')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join ${widget.contest.title}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload your cooking video entry',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Entry title'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title'
                    : null,
                onSaved: (value) => _title = value!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a description'
                    : null,
                onSaved: (value) => _description = value!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  helperText:
                      'For now paste a CloudFront/S3/video URL. Upload UI comes after media module.',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a video URL'
                    : null,
                onSaved: (value) => _videoUrl = value!.trim(),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Submit Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
