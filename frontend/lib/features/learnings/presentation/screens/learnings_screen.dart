import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/widgets/star_rating.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/app_search_field.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/learnings/domain/models/learning.dart';
import 'package:chronicle/features/learnings/presentation/controllers/learning_controller.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';

/// Learning categories as stored in the database, with display info.
enum LearningCategory {
  finance('finance', AppStrings.learningCatFinance, Icons.savings_outlined, AppColors.chartGreen),
  technology('technology', AppStrings.learningCatTechnology, Icons.memory_rounded, AppColors.chartBlue),
  life('life', AppStrings.learningCatLife, Icons.spa_outlined, AppColors.chartOrchid),
  food('food', AppStrings.learningCatFood, Icons.restaurant_rounded, AppColors.chartOrange),
  travel('travel', AppStrings.learningCatTravel, Icons.flight_takeoff_rounded, AppColors.chartTeal),
  other('other', AppStrings.learningCatOther, Icons.lightbulb_outline_rounded, AppColors.chartLemon);

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const LearningCategory(this.key, this.label, this.icon, this.color);

  static LearningCategory? fromKey(String? key) =>
      key == null ? null : values.where((c) => c.key == key.toLowerCase()).firstOrNull;
}

class LearningsScreen extends ConsumerWidget {
  const LearningsScreen({super.key});

  void _showAdd(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddLearningSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learningControllerProvider);
    final controller = ref.read(learningControllerProvider.notifier);
    final learnings = state.filteredLearnings;
    final hasAny = state.learnings.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.learningsTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasAny)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
              child: AppSearchField(hint: AppStrings.learningsSearchHint, onChanged: controller.setSearchQuery),
            ),
          Expanded(
            child: state.isLoading && !hasAny
                ? const Center(child: CircularProgressIndicator())
                : !hasAny
                    ? EmptyState(
                        icon: Icons.lightbulb_outline_rounded,
                        title: AppStrings.learningsEmptyTitle,
                        message: AppStrings.learningsEmptyMessage,
                        actionLabel: AppStrings.learningsAddFirst,
                        onAction: () => _showAdd(context, ref),
                      )
                    : learnings.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: AppStrings.journalNoResultsTitle,
                            message: AppStrings.journalNoResultsMessage,
                            muted: true,
                          )
                        : ListView(
                            // Bottom padding keeps the last card clear of the FAB.
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxxl + AppSpacing.xl),
                            children: groupByMonth<Learning>(
                              items: learnings,
                              dateOf: (l) => l.logDate,
                              header: (label) => SectionHeader(title: label, compact: true),
                              item: (l) => Dismissible(
                                key: ValueKey(l.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) => confirmJournalDelete(context),
                                onDismissed: (_) => controller.deleteLearning(l.id),
                                background: const DeleteSwipeBackground(),
                                child: _LearningCard(learning: l),
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: hasAny
          ? FloatingActionButton.extended(
              onPressed: () => _showAdd(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.learningsAdd),
            )
          : null,
    );
  }
}

class _LearningCard extends StatelessWidget {
  final Learning learning;

  const _LearningCard({required this.learning});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = LearningCategory.fromKey(learning.category);
    final description = learning.description?.trim();
    final source = learning.source?.trim();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (category != null) TagPill(text: category.label, color: category.color, icon: category.icon),
              const Spacer(),
              Text(AppFormatters.dayMonthYear(learning.logDate), style: theme.textTheme.labelSmall),
            ],
          ),
          AppSpacing.gapMd,
          Text(learning.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (description != null && description.isNotEmpty) ...[
            AppSpacing.gapXs,
            Text(description, style: theme.textTheme.bodyMedium),
          ],
          if (learning.usefulnessRating != null || (source != null && source.isNotEmpty)) ...[
            AppSpacing.gapMd,
            Row(
              children: [
                if (source != null && source.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_outlined, size: AppSpacing.md, color: theme.colorScheme.onSurfaceVariant),
                        AppSpacing.hGapXs,
                        Flexible(
                          child: Text(
                            '${AppStrings.learningSourcePrefix} $source',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                if (learning.usefulnessRating != null) StarRatingDisplay(rating: learning.usefulnessRating!.toDouble()),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddLearningSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddLearningSheet({required this.ref});

  @override
  State<_AddLearningSheet> createState() => _AddLearningSheetState();
}

class _AddLearningSheetState extends State<_AddLearningSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _sourceController = TextEditingController();
  LearningCategory _category = LearningCategory.life;
  int _rating = 3;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  static String? _orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    widget.ref.read(learningControllerProvider.notifier).addLearning(Learning(
          id: '',
          userId: '',
          title: title,
          description: _orNull(_descController),
          category: _category.key,
          source: _orNull(_sourceController),
          usefulnessRating: _rating,
          logDate: _date,
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KeyboardAwareSheet(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const JournalSheetHeader(title: AppStrings.learningNewTitle),
          AppSpacing.gapMd,
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: AppStrings.learningTitleLabel),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _descController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: AppStrings.learningDetailsLabel),
            maxLines: 3,
            minLines: 2,
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _sourceController,
            decoration: const InputDecoration(
              labelText: AppStrings.learningSourceLabel,
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          ),
          AppSpacing.gapLg,
          Text(AppStrings.learningCategory, style: theme.textTheme.titleSmall),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final c in LearningCategory.values)
                ChoiceChip(
                  showCheckmark: false,
                  // The theme's chip fill equals the sheet surface; lift it.
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  // Selected chips are filled with the text colour, so the icon
                  // takes the background colour to stay visible.
                  avatar: Icon(c.icon, size: AppSpacing.md, color: _category == c ? theme.scaffoldBackgroundColor : c.color),
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          AppSpacing.gapLg,
          StarRatingInput(
            label: AppStrings.learningUsefulness,
            value: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          AppSpacing.gapSm,
          JournalDateField(value: _date, onChanged: (d) => setState(() => _date = d)),
          AppSpacing.gapLg,
          FilledButton(onPressed: _save, child: const Text(AppStrings.learningSave)),
        ],
      ),
    );
  }
}
