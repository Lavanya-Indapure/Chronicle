import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chronicle/core/constants/app_constants.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/draft_form_mixin.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/core/widgets/storage_image.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/features/miscellaneous/domain/models/misc_item.dart';
import 'package:chronicle/features/miscellaneous/presentation/controllers/misc_controller.dart';

/// Create an item, or edit / delete an existing one. Needs a note, a
/// picture, or both.
class MiscItemSheet extends ConsumerStatefulWidget {
  final MiscItem? item;

  const MiscItemSheet({super.key, this.item});

  @override
  ConsumerState<MiscItemSheet> createState() => _MiscItemSheetState();
}

class _MiscItemSheetState extends ConsumerState<MiscItemSheet> with DraftFormMixin<MiscItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final _titleController = TextEditingController(text: widget.item?.title);
  late final _contentController = TextEditingController(text: widget.item?.content);

  /// Newly picked picture (replaces the saved one on save).
  File? _newImage;

  /// The saved picture should be dropped on save.
  bool _removeImage = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.item != null;
  bool get _hasSavedImage => (widget.item?.hasImage ?? false) && !_removeImage;
  bool get _hasImage => _newImage != null || _hasSavedImage;

  // ── Draft ──
  @override
  String get draftKey => _isEditing ? 'misc:edit:${widget.item!.id}' : 'misc:new';

  @override
  Map<String, Object?> captureDraft() => {
        'title': _titleController.text,
        'content': _contentController.text,
        'imagePath': _newImage?.path,
        'removeImage': _removeImage,
      };

  /// Missing keys fall back to the item being edited (or blank for new). A
  /// picked picture whose temp file is gone is dropped.
  @override
  void restoreDraft(Map<String, Object?> draft) {
    _titleController.text = draft['title'] as String? ?? widget.item?.title ?? '';
    _contentController.text = draft['content'] as String? ?? widget.item?.content ?? '';
    final path = draft['imagePath'] as String?;
    final file = path == null ? null : File(path);
    _newImage = (file != null && file.existsSync()) ? file : null;
    _removeImage = draft['removeImage'] as bool? ?? false;
  }

  @override
  void initState() {
    super.initState();
    initDraft();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) setState(() => _newImage = File(picked.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.pickImageFailed)));
      }
    }
  }

  void _clearImage() => setState(() {
        _newImage = null;
        _removeImage = true;
      });

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

  String? _trimmedOrNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final saved = await ref.read(miscControllerProvider.notifier).saveItem(
          existing: widget.item,
          title: _trimmedOrNull(_titleController),
          content: _trimmedOrNull(_contentController),
          newImage: _newImage,
          removeImage: _removeImage,
        );
    if (!mounted) return;
    // On failure keep the sheet (and the draft); the screen shows the error.
    if (!saved) return setState(() => _isSubmitting = false);
    markSubmitted();
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirmJournalDelete(context, title: AppStrings.miscDeleteTitle)) return;
    if (!mounted) return;
    setState(() => _isSubmitting = true);
    final deleted = await ref.read(miscControllerProvider.notifier).deleteItem(widget.item!.id);
    if (!mounted) return;
    if (!deleted) return setState(() => _isSubmitting = false);
    markSubmitted();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareSheet(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JournalSheetHeader(
              title: _isEditing ? AppStrings.miscEditTitle : AppStrings.miscNewTitle,
              onDelete: _isEditing && !_isSubmitting ? _delete : null,
            ),
            AppSpacing.gapMd,
            if (draftRestored) ...[
              DraftRestoredBanner(onDiscard: discardDraft),
              AppSpacing.gapMd,
            ],
            _ImagePickerArea(
              newImage: _newImage,
              savedPath: _hasSavedImage ? widget.item!.storagePath : null,
              onPick: _showSourceOptions,
              onRemove: _hasImage ? _clearImage : null,
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: AppStrings.miscTitleLabel),
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _contentController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: AppStrings.miscContentLabel,
                hintText: AppStrings.miscContentHint,
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              minLines: 3,
              validator: (v) => (v?.trim().isEmpty ?? true) && !_hasImage ? AppStrings.miscNeedsContent : null,
            ),
            AppSpacing.gapLg,
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(dimension: AppSpacing.md + 4, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? AppStrings.miscUpdate : AppStrings.miscSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picture preview (new local file, or the saved one) with change / remove,
/// or an "add a picture" prompt.
class _ImagePickerArea extends StatelessWidget {
  static const double _height = 180;

  final File? newImage;
  final String? savedPath;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _ImagePickerArea({required this.newImage, required this.savedPath, required this.onPick, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final Widget? preview = newImage != null
        ? Image.file(newImage!, fit: BoxFit.cover)
        : savedPath != null
            ? StorageImage(bucket: AppConstants.miscBucket, path: savedPath!)
            : null;

    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: AppSpacing.borderRadiusXl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPick,
        child: SizedBox(
          height: preview == null ? _height / 2 : _height,
          child: preview == null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: colors.primary),
                    AppSpacing.hGapSm,
                    Flexible(child: Text(AppStrings.miscAddImage, style: theme.textTheme.bodyMedium)),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    preview,
                    Positioned(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Chip(
                        avatar: const Icon(Icons.swap_horiz_rounded),
                        label: const Text(AppStrings.changePhoto),
                        backgroundColor: colors.surface,
                      ),
                    ),
                    if (onRemove != null)
                      Positioned(
                        right: AppSpacing.xs,
                        top: AppSpacing.xs,
                        child: IconButton.filledTonal(
                          tooltip: AppStrings.miscRemoveImage,
                          onPressed: onRemove,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
