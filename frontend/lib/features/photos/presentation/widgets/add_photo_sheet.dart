import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/photos/presentation/controllers/photo_controller.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';

class AddPhotoSheet extends ConsumerStatefulWidget {
  const AddPhotoSheet({super.key});

  @override
  ConsumerState<AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends ConsumerState<AddPhotoSheet> {
  final _captionController = TextEditingController();
  File? _imageFile;
  DateTime _selectedDate = DateTime.now();
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compressing for better storage usage
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);
    final success = await ref.read(photoControllerProvider.notifier).uploadPhoto(
      file: _imageFile!,
      caption: _captionController.text.trim().isEmpty ? null : _captionController.text.trim(),
      date: _selectedDate,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully!')),
        );
      } else {
        setState(() => _isUploading = false);
        final error = ref.read(photoControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to upload photo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardAwareSheet(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add New Memory', style: theme.textTheme.titleLarge),
          AppSpacing.gapLg,

          // Image Preview/Picker
          GestureDetector(
            onTap: () => _showPickerOptions(),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 48, color: theme.colorScheme.primary),
                        AppSpacing.gapSm,
                        Text('Tap to select image', style: theme.textTheme.bodyMedium),
                      ],
                    ),
            ),
          ),
          AppSpacing.gapMd,

          // Caption
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(
              labelText: 'Caption (optional)',
              prefixIcon: Icon(Icons.closed_caption_outlined),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
          AppSpacing.gapMd,

          // Date Picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Photo Date'),
            subtitle: Text(_selectedDate.toString().split(' ').first),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          AppSpacing.gapLg,

          // Upload Button
          FilledButton(
            onPressed: _imageFile == null || _isUploading ? null : _submit,
            child: _isUploading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Capture Memory'),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
