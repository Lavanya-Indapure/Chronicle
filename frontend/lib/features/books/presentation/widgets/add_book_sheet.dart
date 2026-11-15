import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/draft_form_mixin.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/features/books/domain/models/book.dart';
import 'package:chronicle/features/books/presentation/controllers/book_controller.dart';
import 'package:chronicle/core/widgets/star_rating.dart';

/// Add a book, or edit/delete [book] when given.
class AddBookSheet extends ConsumerStatefulWidget {
  final Book? book;

  const AddBookSheet({super.key, this.book});

  @override
  ConsumerState<AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends ConsumerState<AddBookSheet> with DraftFormMixin<AddBookSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.book?.name);
  late final _authorController = TextEditingController(text: widget.book?.author);
  late final _takeawaysController = TextEditingController(text: widget.book?.takeaways);

  late String _status = widget.book?.status ?? 'reading';
  late int? _rating = widget.book?.rating?.round();
  late bool _isFavorite = widget.book?.isFavorite ?? false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.book != null;

  // ── Draft ──
  @override
  String get draftKey => _isEditing ? 'book:edit:${widget.book!.id}' : 'book:new';

  @override
  Map<String, Object?> captureDraft() => {
        'name': _nameController.text,
        'author': _authorController.text,
        'takeaways': _takeawaysController.text,
        'status': _status,
        'rating': _rating,
        'isFavorite': _isFavorite,
      };

  @override
  void restoreDraft(Map<String, Object?> draft) {
    final book = widget.book;
    _nameController.text = draft['name'] as String? ?? book?.name ?? '';
    _authorController.text = draft['author'] as String? ?? book?.author ?? '';
    _takeawaysController.text = draft['takeaways'] as String? ?? book?.takeaways ?? '';
    _status = draft['status'] as String? ?? book?.status ?? 'reading';
    _rating = draft.containsKey('rating') ? draft['rating'] as int? : book?.rating?.round();
    _isFavorite = draft['isFavorite'] as bool? ?? book?.isFavorite ?? false;
  }

  @override
  void initState() {
    super.initState();
    initDraft();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _takeawaysController.dispose();
    super.dispose();
  }

  static String? _orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final controller = ref.read(bookControllerProvider.notifier);
    final ok = _isEditing
        ? await controller.updateBook(
            id: widget.book!.id,
            name: _nameController.text.trim(),
            author: _orNull(_authorController),
            takeaways: _orNull(_takeawaysController),
            status: _status,
            rating: _rating?.toDouble(),
            isFavorite: _isFavorite,
          )
        : await controller.createBook(
            name: _nameController.text.trim(),
            author: _orNull(_authorController),
            takeaways: _orNull(_takeawaysController),
            status: _status,
            rating: _rating?.toDouble(),
            isFavorite: _isFavorite,
          );

    if (ok) markSubmitted();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteBookTitle),
        content: const Text(AppStrings.deleteBookMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final ok = await ref.read(bookControllerProvider.notifier).deleteBook(widget.book!.id);
    if (ok) markSubmitted(); // deleted → no draft to keep
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardAwareSheet(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_isEditing ? AppStrings.editBook : AppStrings.addBook, style: theme.textTheme.titleLarge),
                ),
                if (_isEditing)
                  IconButton(
                    tooltip: AppStrings.delete,
                    onPressed: _isSubmitting ? null : _delete,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
              ],
            ),
            AppSpacing.gapMd,
            if (draftRestored) ...[
              DraftRestoredBanner(onDiscard: discardDraft),
              AppSpacing.gapMd,
            ],
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing && !draftRestored,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: AppStrings.bookTitle, prefixIcon: Icon(Icons.menu_book_rounded)),
              validator: (v) => (v?.trim().isEmpty ?? true) ? AppStrings.bookTitleRequired : null,
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _authorController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: AppStrings.authorOptional, prefixIcon: Icon(Icons.person_outline_rounded)),
            ),
            AppSpacing.gapLg,
            Text(AppStrings.status, style: theme.textTheme.labelMedium),
            AppSpacing.gapSm,
            PillTabs<String>(
              values: const ['reading', 'completed'],
              labelOf: (s) => s == 'completed' ? AppStrings.bookStatusCompleted : AppStrings.bookStatusReading,
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
            ),
            AppSpacing.gapLg,
            Text(AppStrings.rating, style: theme.textTheme.labelMedium),
            StarRatingPicker(value: _rating, allowClear: true, onChanged: (v) => setState(() => _rating = v)),
            AppSpacing.gapSm,
            TextFormField(
              controller: _takeawaysController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: AppStrings.keyTakeaways, alignLabelWithHint: true),
              minLines: 3,
              maxLines: 5,
            ),
            AppSpacing.gapSm,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.markFavorite),
              secondary: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavorite ? AppColors.error : theme.colorScheme.onSurfaceVariant,
              ),
              value: _isFavorite,
              onChanged: (v) => setState(() => _isFavorite = v),
            ),
            AppSpacing.gapMd,
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(dimension: AppSpacing.lg - 4, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? AppStrings.saveChanges : AppStrings.addToLibrary),
            ),
          ],
        ),
      ),
    );
  }
}
