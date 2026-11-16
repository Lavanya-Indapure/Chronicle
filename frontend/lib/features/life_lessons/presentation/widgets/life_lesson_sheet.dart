import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/draft_form_mixin.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/features/life_lessons/domain/models/life_lesson.dart';
import 'package:chronicle/features/life_lessons/presentation/controllers/life_lesson_controller.dart';

/// Create a life lesson, or edit / delete an existing one.
class LifeLessonSheet extends ConsumerStatefulWidget {
  final LifeLesson? lesson;

  const LifeLessonSheet({super.key, this.lesson});

  @override
  ConsumerState<LifeLessonSheet> createState() => _LifeLessonSheetState();
}

class _LifeLessonSheetState extends ConsumerState<LifeLessonSheet> with DraftFormMixin<LifeLessonSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.lesson?.title);
  late final _contentController = TextEditingController(text: widget.lesson?.content);
  late final _tagsController = TextEditingController(text: widget.lesson?.tags.join(', '));
  bool _isSubmitting = false;

  bool get _isEditing => widget.lesson != null;

  // ── Draft ──
  @override
  String get draftKey => _isEditing ? 'lifeLesson:edit:${widget.lesson!.id}' : 'lifeLesson:new';

  @override
  Map<String, Object?> captureDraft() => {
        'title': _titleController.text,
        'content': _contentController.text,
        'tags': _tagsController.text,
      };

  /// Missing keys fall back to the lesson being edited (or blank for new).
  @override
  void restoreDraft(Map<String, Object?> draft) {
    _titleController.text = draft['title'] as String? ?? widget.lesson?.title ?? '';
    _contentController.text = draft['content'] as String? ?? widget.lesson?.content ?? '';
    _tagsController.text = draft['tags'] as String? ?? widget.lesson?.tags.join(', ') ?? '';
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
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();

    setState(() => _isSubmitting = true);
    final saved = await ref.read(lifeLessonControllerProvider.notifier).saveLesson(
          id: widget.lesson?.id,
          title: title.isEmpty ? null : title,
          content: _contentController.text.trim(),
          tags: LifeLesson.parseTags(_tagsController.text),
        );
    if (!mounted) return;
    // On failure keep the sheet (and the draft) so nothing typed is lost;
    // the screen shows the error.
    if (!saved) return setState(() => _isSubmitting = false);
    markSubmitted();
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirmJournalDelete(context, title: AppStrings.lifeLessonDeleteTitle)) return;
    if (!mounted) return;
    setState(() => _isSubmitting = true);
    final deleted = await ref.read(lifeLessonControllerProvider.notifier).deleteLesson(widget.lesson!.id);
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
              title: _isEditing ? AppStrings.lifeLessonEditTitle : AppStrings.lifeLessonNewTitle,
              onDelete: _isEditing && !_isSubmitting ? _delete : null,
            ),
            AppSpacing.gapMd,
            if (draftRestored) ...[
              DraftRestoredBanner(onDiscard: discardDraft),
              AppSpacing.gapMd,
            ],
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.lifeLessonTitleLabel,
                hintText: AppStrings.lifeLessonTitleHint,
              ),
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _contentController,
              autofocus: !_isEditing && !draftRestored,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: AppStrings.lifeLessonContentLabel,
                hintText: AppStrings.lifeLessonContentHint,
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              minLines: 3,
              validator: (v) => (v?.trim().isEmpty ?? true) ? AppStrings.lifeLessonContentRequired : null,
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: AppStrings.lifeLessonTagsLabel,
                hintText: AppStrings.lifeLessonTagsHint,
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            AppSpacing.gapLg,
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(dimension: AppSpacing.md + 4, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? AppStrings.lifeLessonUpdate : AppStrings.lifeLessonSave),
            ),
          ],
        ),
      ),
    );
  }
}
