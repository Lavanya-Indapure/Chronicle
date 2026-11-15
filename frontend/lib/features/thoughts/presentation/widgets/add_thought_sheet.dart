import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/draft_form_mixin.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/features/thoughts/domain/models/thought.dart';
import 'package:chronicle/features/thoughts/presentation/controllers/thought_controller.dart';

/// Create a thought, or edit / delete an existing one.
class AddThoughtSheet extends ConsumerStatefulWidget {
  final Thought? thought;

  const AddThoughtSheet({super.key, this.thought});

  @override
  ConsumerState<AddThoughtSheet> createState() => _AddThoughtSheetState();
}

class _AddThoughtSheetState extends ConsumerState<AddThoughtSheet> with DraftFormMixin<AddThoughtSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _contentController = TextEditingController(text: widget.thought?.content);
  late final _tagsController = TextEditingController(text: widget.thought?.tags);
  bool _isSubmitting = false;

  bool get _isEditing => widget.thought != null;

  // ── Draft ──
  @override
  String get draftKey => _isEditing ? 'thought:edit:${widget.thought!.id}' : 'thought:new';

  @override
  Map<String, Object?> captureDraft() => {
        'content': _contentController.text,
        'tags': _tagsController.text,
      };

  /// Missing keys fall back to the thought being edited (or blank for new).
  @override
  void restoreDraft(Map<String, Object?> draft) {
    _contentController.text = draft['content'] as String? ?? widget.thought?.content ?? '';
    _tagsController.text = draft['tags'] as String? ?? widget.thought?.tags ?? '';
  }

  @override
  void initState() {
    super.initState();
    initDraft();
  }

  /// The controller reports failures via `errorMessage` (cleared on every
  /// state change), not a return value.
  bool get _lastActionFailed => ref.read(thoughtControllerProvider).errorMessage != null;

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final content = _contentController.text.trim();
    final tags = _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim();
    final controller = ref.read(thoughtControllerProvider.notifier);

    setState(() => _isSubmitting = true);
    try {
      if (_isEditing) {
        await controller.updateThought(widget.thought!.id, content, tags);
      } else {
        await controller.createThought(content, tags);
      }
      // On failure keep the sheet (and the draft) so nothing typed is lost.
      if (_lastActionFailed) return;
      markSubmitted();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmJournalDelete(context, title: AppStrings.thoughtDeleteTitle)) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(thoughtControllerProvider.notifier).deleteThought(widget.thought!.id);
      if (_lastActionFailed) return;
      markSubmitted();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              title: _isEditing ? AppStrings.thoughtEditTitle : AppStrings.thoughtCaptureTitle,
              onDelete: _isEditing && !_isSubmitting ? _delete : null,
            ),
            AppSpacing.gapMd,
            if (draftRestored) ...[
              DraftRestoredBanner(onDiscard: discardDraft),
              AppSpacing.gapMd,
            ],
            TextFormField(
              controller: _contentController,
              autofocus: !_isEditing && !draftRestored,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: AppStrings.thoughtContentLabel,
                hintText: AppStrings.thoughtContentHint,
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 3,
              validator: (v) => (v?.trim().isEmpty ?? true) ? AppStrings.thoughtContentRequired : null,
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: AppStrings.thoughtTagsLabel,
                hintText: AppStrings.thoughtTagsHint,
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            AppSpacing.gapLg,
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(dimension: AppSpacing.md + 4, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? AppStrings.thoughtUpdate : AppStrings.thoughtSave),
            ),
          ],
        ),
      ),
    );
  }
}
