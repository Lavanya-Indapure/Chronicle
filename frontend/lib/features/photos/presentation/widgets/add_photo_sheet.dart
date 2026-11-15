import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/draft_form_mixin.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/features/photos/presentation/controllers/photo_controller.dart';

/// Pick a photo (gallery or camera), add an optional caption and date, upload.
class AddPhotoSheet extends ConsumerStatefulWidget {
  const AddPhotoSheet({super.key});

  @override
  ConsumerState<AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends ConsumerState<AddPhotoSheet> with DraftFormMixin<AddPhotoSheet> {
  /// Height of the image preview / picker area.
  static const double _previewHeight = 200;

  final _captionController = TextEditingController();
  File? _imageFile;
  DateTime _selectedDate = DateTime.now();
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  // ── Draft ──
  @override
  String get draftKey => 'photo:new';

  @override
  Map<String, Object?> captureDraft() => {
        'imagePath': _imageFile?.path,
        'caption': _captionController.text,
        'date': _selectedDate,
      };

  /// A picked image whose file no longer exists (e.g. the picker's temp copy
  /// was cleaned up) is dropped; caption and date are still restored.
  @override
  void restoreDraft(Map<String, Object?> draft) {
    final path = draft['imagePath'] as String?;
    final file = path == null ? null : File(path);
    _imageFile = (file != null && file.existsSync()) ? file : null;
    _captionController.text = draft['caption'] as String? ?? '';
    _selectedDate = draft['date'] as DateTime? ?? DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    initDraft();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.pickImageFailed)));
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _submit() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);
    final success = await ref.read(photoControllerProvider.notifier).uploadPhoto(
          file: _imageFile!,
          caption: _captionController.text.trim().isEmpty ? null : _captionController.text.trim(),
          date: _selectedDate,
        );
    if (success) markSubmitted();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text(AppStrings.photoUploaded)));
    } else {
      setState(() => _isUploading = false);
      final error = ref.read(photoControllerProvider).errorMessage;
      messenger.showSnackBar(SnackBar(content: Text(error ?? AppStrings.photoUploadFailed)));
    }
  }

  void _showSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text(AppStrings.gallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text(AppStrings.camera),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return KeyboardAwareSheet(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.addNewMemory, style: theme.textTheme.titleLarge),
          AppSpacing.gapLg,
          if (draftRestored) ...[
            DraftRestoredBanner(onDiscard: discardDraft),
            AppSpacing.gapMd,
          ],

          // Preview / picker
          Material(
            color: colors.surfaceContainerHigh,
            borderRadius: AppSpacing.borderRadiusXl,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _showSourceOptions,
              child: SizedBox(
                height: _previewHeight,
                child: _imageFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_imageFile!, fit: BoxFit.cover),
                          Positioned(
                            right: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                            child: Chip(
                              avatar: const Icon(Icons.swap_horiz_rounded),
                              label: const Text(AppStrings.changePhoto),
                              backgroundColor: colors.surface,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: AppSpacing.xxl, color: colors.primary),
                          AppSpacing.gapSm,
                          Text(AppStrings.tapToSelectImage, style: theme.textTheme.bodyMedium),
                        ],
                      ),
              ),
            ),
          ),
          AppSpacing.gapMd,

          TextField(
            controller: _captionController,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: AppStrings.captionOptional,
              prefixIcon: Icon(Icons.short_text_rounded),
            ),
          ),
          AppSpacing.gapMd,

          // Date
          Material(
            color: colors.surfaceContainerHigh,
            borderRadius: AppSpacing.borderRadiusLg,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: _pickDate,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text(AppStrings.photoDate),
              trailing: Text(AppFormatters.dayMonthYear(_selectedDate), style: theme.textTheme.titleSmall),
            ),
          ),
          AppSpacing.gapLg,

          FilledButton(
            onPressed: _imageFile == null || _isUploading ? null : _submit,
            child: _isUploading
                ? const SizedBox.square(dimension: AppSpacing.md + 4, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(AppStrings.saveMemory),
          ),
        ],
      ),
    );
  }
}
