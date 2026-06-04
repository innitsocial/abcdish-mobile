import 'package:flutter/material.dart';

class CreatorUploadScreen extends StatefulWidget {
  const CreatorUploadScreen({super.key});

  @override
  State<CreatorUploadScreen> createState() => _CreatorUploadScreenState();
}

class _CreatorUploadScreenState extends State<CreatorUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _imageUrl = '';
  String _videoUrl = '';
  String _mediaType = 'VIDEO';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Creator upload UI is ready. S3 upload integration is the next backend step.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Upload')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.video_call, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Upload a recipe or cooking video',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _mediaType,
                    decoration: const InputDecoration(labelText: 'Media type'),
                    items: const [
                      DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                      DropdownMenuItem(value: 'IMAGE', child: Text('Image')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _mediaType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Enter title'
                        : null,
                    onSaved: (value) => _title = value!.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    onSaved: (value) => _description = value?.trim() ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Image URL'),
                    onSaved: (value) => _imageUrl = value?.trim() ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Video URL'),
                    onSaved: (value) => _videoUrl = value?.trim() ?? '',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.upload),
                      label: const Text('Save Draft'),
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
