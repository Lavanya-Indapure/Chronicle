import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/app_search_field.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/core/widgets/tag_filter_row.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/features/thoughts/domain/models/thought.dart';
import 'package:chronicle/features/thoughts/presentation/controllers/thought_controller.dart';
import 'package:chronicle/features/thoughts/presentation/widgets/add_thought_sheet.dart';

class ThoughtsScreen extends ConsumerWidget {
  const ThoughtsScreen({super.key});

  static void _openSheet(BuildContext context, {Thought? thought}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddThoughtSheet(thought: thought),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(thoughtControllerProvider);
    final controller = ref.read(thoughtControllerProvider.notifier);
    final thoughts = state.filteredThoughts;
    final hasAny = state.thoughts.isNotEmpty;

    ref.listen(thoughtControllerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.thoughtsTitle),
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
                  icon: Icons.format_quote_rounded,
                  title: AppStrings.thoughtsEmptyTitle,
                  message: AppStrings.thoughtsEmptyMessage,
                  actionLabel: AppStrings.thoughtsAddFirst,
                  onAction: () => _openSheet(context),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
                      child: AppSearchField(hint: AppStrings.thoughtsSearchHint, onChanged: controller.setSearchQuery),
                    ),
                    if (state.allTags.isNotEmpty) ...[
                      TagFilterRow(
                        tags: state.allTags,
                        selected: state.selectedTag,
                        onSelected: controller.setSelectedTag,
                      ),
                      AppSpacing.gapMd,
                    ],
                    Expanded(
                      child: thoughts.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: AppStrings.journalNoResultsTitle,
                              message: AppStrings.journalNoResultsMessage,
                              muted: true,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xxxl + AppSpacing.xl),
                              itemCount: thoughts.length,
                              separatorBuilder: (_, _) => AppSpacing.gapSm,
                              itemBuilder: (context, index) => _ThoughtCard(
                                thought: thoughts[index],
                                onTap: () => _openSheet(context, thought: thoughts[index]),
                                onToggleFavorite: () => controller.toggleFavorite(thoughts[index]),
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: hasAny
          ? FloatingActionButton.extended(
              onPressed: () => _openSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.thoughtsAdd),
            )
          : null,
    );
  }
}

class _ThoughtCard extends StatelessWidget {
  final Thought thought;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _ThoughtCard({required this.thought, required this.onTap, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
                child: Icon(Icons.format_quote_rounded, color: colors.primary, size: AppSpacing.lg),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    thought.content,
                    style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              IconButton(
                tooltip: AppStrings.thoughtFavorite,
                isSelected: thought.isFavorite,
                onPressed: onToggleFavorite,
                icon: Icon(Icons.favorite_border_rounded, color: colors.onSurfaceVariant),
                selectedIcon: const Icon(Icons.favorite_rounded, color: AppColors.error),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md - 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [for (final tag in thought.tags) TagPill(text: '#$tag', color: AppColors.chartBlue)],
                  ),
                ),
                AppSpacing.hGapSm,
                Text(AppFormatters.dayMonthYear(thought.createdAt), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
