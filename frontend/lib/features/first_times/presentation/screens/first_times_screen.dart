import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/widgets/star_rating.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/first_times/domain/models/first_time_experience.dart';
import 'package:chronicle/features/first_times/presentation/controllers/first_time_controller.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';

/// Feelings as stored in the database, with an emoji and accent colour.
enum FirstFeeling {
  happy('happy', AppStrings.feelingHappy, '😊', AppColors.chartGreen),
  excited('excited', AppStrings.feelingExcited, '🤩', AppColors.chartLemon),
  amazed('amazed', AppStrings.feelingAmazed, '😲', AppColors.chartBlue),
  nervous('nervous', AppStrings.feelingNervous, '😬', AppColors.chartOrchid),
  scared('scared', AppStrings.feelingScared, '😱', AppColors.chartCoral);

  final String key;
  final String label;
  final String emoji;
  final Color color;

  const FirstFeeling(this.key, this.label, this.emoji, this.color);

  static FirstFeeling? fromKey(String? key) =>
      key == null ? null : values.where((f) => f.key == key.toLowerCase()).firstOrNull;
}

class FirstTimeExperiencesScreen extends ConsumerWidget {
  const FirstTimeExperiencesScreen({super.key});

  void _showAdd(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddFirstTimeSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(firstTimeControllerProvider);
    final controller = ref.read(firstTimeControllerProvider.notifier);
    final experiences = state.experiences;
    final hasAny = experiences.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.firstsTitle)),
      body: state.isLoading && !hasAny
          ? const Center(child: CircularProgressIndicator())
          : !hasAny
              ? EmptyState(
                  icon: Icons.auto_awesome_rounded,
                  title: AppStrings.firstsEmptyTitle,
                  message: AppStrings.firstsEmptyMessage,
                  actionLabel: AppStrings.firstsAddFirst,
                  onAction: () => _showAdd(context, ref),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxxl + AppSpacing.xl),
                  children: [
                    _FirstsSummary(experiences: experiences),
                    AppSpacing.gapLg,
                    ...groupByMonth<FirstTimeExperience>(
                      items: experiences,
                      dateOf: (e) => e.logDate,
                      header: (label) => SectionHeader(title: label, compact: true),
                      item: (e) => Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => confirmJournalDelete(context),
                        onDismissed: (_) => controller.deleteExperience(e.id),
                        background: const DeleteSwipeBackground(),
                        child: _FirstTimeCard(exp: e),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: hasAny
          ? FloatingActionButton.extended(
              onPressed: () => _showAdd(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.firstsAdd),
            )
          : null,
    );
  }
}

/// Lemon banner: "12 firsts · 3 this year".
class _FirstsSummary extends StatelessWidget {
  final List<FirstTimeExperience> experiences;

  const _FirstsSummary({required this.experiences});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onPrimaryContainer;
    final thisYear = experiences.where((e) => e.logDate.year == DateTime.now().year).length;

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppSpacing.borderRadiusXl),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: ink, size: AppSpacing.xl),
          AppSpacing.hGapMd,
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${experiences.length} ',
                    style: theme.textTheme.headlineMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: AppStrings.firstsTotalSuffix, style: theme.textTheme.titleMedium?.copyWith(color: ink)),
                ],
              ),
            ),
          ),
          Text('$thisYear ${AppStrings.firstsThisYearSuffix}', style: theme.textTheme.labelLarge?.copyWith(color: ink)),
        ],
      ),
    );
  }
}

class _FirstTimeCard extends StatelessWidget {
  final FirstTimeExperience exp;

  const _FirstTimeCard({required this.exp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final feeling = FirstFeeling.fromKey(exp.emotion);
    final description = exp.description?.trim();
    final location = exp.location?.trim();

    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.iconBadgeSize,
            height: AppSpacing.iconBadgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (feeling?.color ?? colors.primary).withValues(alpha: 0.18),
            ),
            child: feeling != null
                ? Text(feeling.emoji, style: theme.textTheme.titleLarge)
                : Icon(Icons.auto_awesome_rounded, color: colors.primary),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                AppSpacing.gapXs,
                Text(AppFormatters.dayMonthYear(exp.logDate), style: theme.textTheme.bodySmall),
                if (description != null && description.isNotEmpty) ...[
                  AppSpacing.gapSm,
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
                if (feeling != null || exp.rating != null || (location != null && location.isNotEmpty)) ...[
                  AppSpacing.gapMd,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (feeling != null) TagPill(text: feeling.label, color: feeling.color),
                      if (location != null && location.isNotEmpty)
                        TagPill(text: location, color: AppColors.chartTeal, icon: Icons.place_outlined),
                      if (exp.rating != null) StarRatingDisplay(rating: exp.rating!.toDouble()),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFirstTimeSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddFirstTimeSheet({required this.ref});

  @override
  State<_AddFirstTimeSheet> createState() => _AddFirstTimeSheetState();
}

class _AddFirstTimeSheetState extends State<_AddFirstTimeSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locController = TextEditingController();
  FirstFeeling _feeling = FirstFeeling.excited;
  int _rating = 5;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locController.dispose();
    super.dispose();
  }

  static String? _orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    widget.ref.read(firstTimeControllerProvider.notifier).createExperience(FirstTimeExperience(
          id: '',
          userId: '',
          title: title,
          description: _orNull(_descController),
          logDate: _date,
          emotion: _feeling.key,
          rating: _rating,
          location: _orNull(_locController),
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
          const JournalSheetHeader(title: AppStrings.firstNewTitle),
          AppSpacing.gapMd,
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: AppStrings.firstTitleLabel),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _descController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: AppStrings.firstDescriptionLabel),
            maxLines: 3,
            minLines: 2,
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _locController,
            decoration: const InputDecoration(
              labelText: AppStrings.firstLocationLabel,
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          AppSpacing.gapLg,
          Text(AppStrings.firstFeeling, style: theme.textTheme.titleSmall),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final f in FirstFeeling.values)
                ChoiceChip(
                  showCheckmark: false,
                  // The theme's chip fill equals the sheet surface; lift it.
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  label: Text('${f.emoji}  ${f.label}'),
                  selected: _feeling == f,
                  onSelected: (_) => setState(() => _feeling = f),
                ),
            ],
          ),
          AppSpacing.gapLg,
          StarRatingInput(
            label: AppStrings.journalRating,
            value: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          AppSpacing.gapSm,
          JournalDateField(value: _date, onChanged: (d) => setState(() => _date = d)),
          AppSpacing.gapLg,
          FilledButton(onPressed: _save, child: const Text(AppStrings.firstSave)),
        ],
      ),
    );
  }
}
