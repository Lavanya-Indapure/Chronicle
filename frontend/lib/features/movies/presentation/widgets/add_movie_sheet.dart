import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/draft_form_mixin.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/core/widgets/star_rating.dart';
import 'package:chronicle/features/movies/domain/models/movie.dart';
import 'package:chronicle/features/movies/presentation/controllers/movie_controller.dart';
import 'package:chronicle/features/movies/presentation/widgets/movie_platform.dart';

/// Log a movie, or edit/delete [movie] when given.
class AddMovieSheet extends ConsumerStatefulWidget {
  final Movie? movie;

  const AddMovieSheet({super.key, this.movie});

  @override
  ConsumerState<AddMovieSheet> createState() => _AddMovieSheetState();
}

class _AddMovieSheetState extends ConsumerState<AddMovieSheet> with DraftFormMixin<AddMovieSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.movie?.name);
  late final _costController = TextEditingController(text: _formatCost(widget.movie?.cost));
  late final _commentsController = TextEditingController(text: widget.movie?.comments);
  late final _takeawaysController = TextEditingController(text: widget.movie?.takeaways);

  late DateTime _watchDate = widget.movie?.watchDate ?? DateTime.now();
  late String _platform = widget.movie?.platform ?? MoviePlatform.digital;
  late int _rating = widget.movie?.rating ?? 3;
  bool _isSubmitting = false;

  bool get _isEditing => widget.movie != null;
  bool get _isTheatre => _platform == MoviePlatform.theatre;

  /// 250.0 → "250", 249.5 → "249.5"
  static String? _formatCost(double? v) =>
      v == null ? null : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  static String? _orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  // ── Draft ──
  @override
  String get draftKey => _isEditing ? 'movie:edit:${widget.movie!.id}' : 'movie:new';

  @override
  Map<String, Object?> captureDraft() => {
        'name': _nameController.text,
        'cost': _costController.text,
        'comments': _commentsController.text,
        'takeaways': _takeawaysController.text,
        'watchDate': _watchDate,
        'platform': _platform,
        'rating': _rating,
      };

  /// Missing keys fall back to the movie being edited (or blank for new).
  @override
  void restoreDraft(Map<String, Object?> draft) {
    final m = widget.movie;
    _nameController.text = draft['name'] as String? ?? m?.name ?? '';
    _costController.text = draft['cost'] as String? ?? _formatCost(m?.cost) ?? '';
    _commentsController.text = draft['comments'] as String? ?? m?.comments ?? '';
    _takeawaysController.text = draft['takeaways'] as String? ?? m?.takeaways ?? '';
    _watchDate = draft['watchDate'] as DateTime? ?? m?.watchDate ?? DateTime.now();
    _platform = draft['platform'] as String? ?? m?.platform ?? MoviePlatform.digital;
    _rating = draft['rating'] as int? ?? m?.rating ?? 3;
  }

  @override
  void initState() {
    super.initState();
    initDraft();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _commentsController.dispose();
    _takeawaysController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _watchDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _watchDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final movie = Movie(
      id: widget.movie?.id ?? '',
      userId: widget.movie?.userId ?? '',
      name: _nameController.text.trim(),
      watchDate: _watchDate,
      platform: _platform,
      rating: _rating,
      cost: _isTheatre ? double.tryParse(_costController.text.trim()) : null,
      comments: _orNull(_commentsController),
      takeaways: _orNull(_takeawaysController),
    );
    final controller = ref.read(movieControllerProvider.notifier);
    final ok = _isEditing ? await controller.updateMovie(widget.movie!.id, movie) : await controller.createMovie(movie);
    if (ok) markSubmitted();

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteMovieTitle),
        content: const Text(AppStrings.deleteMovieMessage),
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
    final ok = await ref.read(movieControllerProvider.notifier).deleteMovie(widget.movie!.id);
    if (ok) markSubmitted();
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
                  child: Text(_isEditing ? AppStrings.editMovie : AppStrings.logMovie, style: theme.textTheme.titleLarge),
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
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: AppStrings.movieName, prefixIcon: Icon(Icons.movie_outlined)),
              validator: (v) => (v?.trim().isEmpty ?? true) ? AppStrings.movieNameRequired : null,
            ),
            AppSpacing.gapMd,
            Material(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: AppSpacing.borderRadiusLg,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: _pickDate,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text(AppStrings.watchedOn),
                trailing: Text(AppFormatters.dayMonthYear(_watchDate), style: theme.textTheme.titleSmall),
              ),
            ),
            AppSpacing.gapLg,
            Text(AppStrings.platform, style: theme.textTheme.labelMedium),
            AppSpacing.gapSm,
            PillTabs<String>(
              values: const [MoviePlatform.digital, MoviePlatform.theatre],
              labelOf: MoviePlatform.label,
              selected: _platform,
              onChanged: (p) => setState(() => _platform = p),
            ),
            if (_isTheatre) ...[
              AppSpacing.gapMd,
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: AppStrings.ticketCost, prefixIcon: Icon(Icons.currency_rupee_rounded)),
                validator: (v) => _isTheatre && double.tryParse(v?.trim() ?? '') == null ? AppStrings.ticketCostRequired : null,
              ),
            ],
            AppSpacing.gapLg,
            Text(AppStrings.rating, style: theme.textTheme.labelMedium),
            StarRatingPicker(value: _rating, onChanged: (v) => setState(() => _rating = v ?? _rating)),
            AppSpacing.gapSm,
            TextFormField(
              controller: _commentsController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: AppStrings.commentsOptional, alignLabelWithHint: true),
              minLines: 2,
              maxLines: 4,
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _takeawaysController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: AppStrings.takeawaysOptional, alignLabelWithHint: true),
              minLines: 2,
              maxLines: 4,
            ),
            AppSpacing.gapLg,
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(dimension: AppSpacing.lg - 4, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? AppStrings.saveChanges : AppStrings.logMovie),
            ),
          ],
        ),
      ),
    );
  }
}
