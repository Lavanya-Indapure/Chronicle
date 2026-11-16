import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/features/life_lessons/domain/models/life_lesson.dart';

/// One lesson: optional title, the lesson text, tags and date, with a
/// favourite toggle. Tap to edit.
class LifeLessonCard extends StatelessWidget {
  final LifeLesson lesson;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const LifeLessonCard({super.key, required this.lesson, required this.onTap, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = lesson.title?.trim();

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(AppSpacing.cardPadding, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Icon(Icons.psychology_rounded, color: AppColors.chartTeal, size: AppSpacing.lg),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null && title.isNotEmpty) ...[
                        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        AppSpacing.gapXs,
                      ],
                      Text(lesson.content, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: AppStrings.thoughtFavorite,
                isSelected: lesson.isFavorite,
                onPressed: onToggleFavorite,
                icon: Icon(Icons.favorite_border_rounded, color: colors.onSurfaceVariant),
                selectedIcon: const Icon(Icons.favorite_rounded, color: AppColors.error),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm + AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [for (final tag in lesson.tags) TagPill(text: '#$tag', color: AppColors.chartTeal)],
                  ),
                ),
                AppSpacing.hGapSm,
                Text(AppFormatters.dayMonthYear(lesson.createdAt), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal "All · #career · #patience" filter chips.
class LessonTagFilterRow extends StatelessWidget {
  final List<String> tags;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const LessonTagFilterRow({super.key, required this.tags, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.xxl - AppSpacing.xs,
      child: ListView.separated(
        padding: AppSpacing.paddingGutter,
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        separatorBuilder: (_, _) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              showCheckmark: false,
              label: const Text(AppStrings.journalAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final tag = tags[index - 1];
          return ChoiceChip(
            showCheckmark: false,
            label: Text('#$tag'),
            selected: selected == tag,
            onSelected: (v) => onSelected(v ? tag : null),
          );
        },
      ),
    );
  }
}
