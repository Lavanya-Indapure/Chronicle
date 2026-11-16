import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/app_search_field.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/features/life_lessons/domain/models/life_lesson.dart';
import 'package:chronicle/features/life_lessons/presentation/controllers/life_lesson_controller.dart';
import 'package:chronicle/features/life_lessons/presentation/widgets/life_lesson_card.dart';
import 'package:chronicle/features/life_lessons/presentation/widgets/life_lesson_sheet.dart';

/// Life lessons: search, tag filter, favourites; tap a card to edit.
class LifeLessonsScreen extends ConsumerWidget {
  const LifeLessonsScreen({super.key});

  static void _openSheet(BuildContext context, {LifeLesson? lesson}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LifeLessonSheet(lesson: lesson),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lifeLessonControllerProvider);
    final controller = ref.read(lifeLessonControllerProvider.notifier);
    final lessons = state.filteredLessons;
    final hasAny = state.lessons.isNotEmpty;

    ref.listen(lifeLessonControllerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.lifeLessonsLabel),
        actions: [
          if (hasAny)
            IconButton(
              tooltip: AppStrings.thoughtsFavoritesOnly,
              isSelected: state.onlyFavorites,
              icon: const Icon(Icons.favorite_border_rounded),
              selectedIcon: const Icon(Icons.favorite_rounded, color: AppColors.error),
              onPressed: controller.toggleOnlyFavorites,
            ),
          AppSpacing.hGapXs,
        ],
      ),
      body: state.isLoading && !hasAny
          ? const Center(child: CircularProgressIndicator())
          : !hasAny
              ? EmptyState(
                  icon: Icons.psychology_rounded,
                  title: AppStrings.lifeLessonsEmptyTitle,
                  message: AppStrings.lifeLessonsEmptyMessage,
                  actionLabel: AppStrings.lifeLessonsAddFirst,
                  onAction: () => _openSheet(context),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
                      child: AppSearchField(hint: AppStrings.lifeLessonsSearchHint, onChanged: controller.setSearchQuery),
                    ),
                    if (state.allTags.isNotEmpty) ...[
                      LessonTagFilterRow(
                        tags: state.allTags,
                        selected: state.selectedTag,
                        onSelected: controller.setSelectedTag,
                      ),
                      AppSpacing.gapMd,
                    ],
                    Expanded(
                      child: lessons.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: AppStrings.journalNoResultsTitle,
                              message: AppStrings.journalNoResultsMessage,
                              muted: true,
                            )
                          : RefreshIndicator(
                              onRefresh: controller.loadLessons,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxxl + AppSpacing.xl),
                                itemCount: lessons.length,
                                separatorBuilder: (_, _) => AppSpacing.gapSm,
                                itemBuilder: (context, index) => LifeLessonCard(
                                  lesson: lessons[index],
                                  onTap: () => _openSheet(context, lesson: lessons[index]),
                                  onToggleFavorite: () => controller.toggleFavorite(lessons[index]),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: hasAny
          ? FloatingActionButton.extended(
              onPressed: () => _openSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.lifeLessonsAdd),
            )
          : null,
    );
  }
}
