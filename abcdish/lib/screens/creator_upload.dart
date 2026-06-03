import 'package:flutter/material.dart';

import 'package:abcdish/models/media_upload.dart';
import 'package:abcdish/services/media_service.dart';

class CreatorUploadScreen extends StatefulWidget {
  const CreatorUploadScreen({super.key});

  @override
  State<CreatorUploadScreen> createState() => _CreatorUploadScreenState();
}

class _CreatorUploadScreenState extends State<CreatorUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fileName = '';
  String _contentType = 'video/mp4';
  String _mediaType = 'RECIPE_VIDEO';
  bool _loading = false;

  Future<void> _requestUpload() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);
    try {
      final response = await MediaService.instance.requestUpload(
        MediaUploadRequest(
          fileName: _fileName,
          contentType: _contentType,
          mediaType: _mediaType,
        ),
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Upload URL created'),
          content: SelectableText(
            'Upload URL:\n${response.uploadUrl}\n\nPublic URL:\n${response.publicUrl}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create upload URL: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Upload')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Upload cooking media',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'This uses the backend media module to request an upload URL. Full native file picker/S3 upload can be connected next.',
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'File name',
                    hintText: 'my-recipe.mp4',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a file name'
                      : null,
                  onSaved: (value) => _fileName = value!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _contentType,
                  decoration: const InputDecoration(labelText: 'Content type'),
                  onSaved: (value) =>
                      _contentType = value?.trim().isEmpty == true
                      ? 'video/mp4'
                      : value!.trim(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _mediaType,
                  decoration: const InputDecoration(labelText: 'Media type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'RECIPE_VIDEO',
                      child: Text('Recipe Video'),
                    ),
                    DropdownMenuItem(
                      value: 'CONTEST_ENTRY',
                      child: Text('Contest Entry'),
                    ),
                    DropdownMenuItem(
                      value: 'THUMBNAIL',
                      child: Text('Thumbnail'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _mediaType = value ?? 'RECIPE_VIDEO'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _requestUpload,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: const Text('Request Upload URL'),
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
