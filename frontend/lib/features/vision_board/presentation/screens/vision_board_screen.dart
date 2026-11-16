import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';
import 'package:chronicle/features/vision_board/presentation/widgets/add_goal_sheet.dart';
import 'package:chronicle/features/vision_board/presentation/widgets/vision_goal_card.dart';

class VisionBoardScreen extends ConsumerWidget {
  const VisionBoardScreen({super.key});

  /// Status filter values; null = all.
  static const List<String?> _statuses = [null, 'in_progress', 'completed'];

  static String _statusLabel(String? s) => switch (s) {
        'in_progress' => AppStrings.statusInProgress,
        'completed' => AppStrings.statusCompleted,
        _ => AppStrings.statusAll,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionBoardControllerProvider);
    final controller = ref.read(visionBoardControllerProvider.notifier);
    final goals = state.filteredGoals;
    final hasAnyGoal = state.goals.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.visionBoardLabel),
        actions: [
          IconButton(
            tooltip: AppStrings.favoritesOnly,
            isSelected: state.onlyFavorites,
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded, color: AppColors.error),
            onPressed: controller.toggleOnlyFavorites,
          ),
          PopupMenuButton<VisionSort>(
            tooltip: AppStrings.sortBy,
            icon: const Icon(Icons.sort_rounded),
            onSelected: controller.setSortBy,
            itemBuilder: (context) => [
              for (final (sort, label) in const [
                (VisionSort.recency, AppStrings.sortRecency),
                (VisionSort.deadline, AppStrings.sortDeadline),
                (VisionSort.progress, AppStrings.sortProgress),
              ])
                CheckedPopupMenuItem(value: sort, checked: state.sortBy == sort, child: Text(label)),
            ],
          ),
          AppSpacing.hGapXs,
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
            child: TextField(
              onChanged: controller.setSearchQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppStrings.searchGoalsHint,
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusPill, borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusPill, borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusPill,
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.paddingGutter,
            child: PillTabs<String?>(
              values: _statuses,
              labelOf: _statusLabel,
              selected: state.statusFilter,
              onChanged: controller.setStatusFilter,
            ),
          ),
          Expanded(
            child: state.isLoading && !hasAnyGoal
                ? const Center(child: CircularProgressIndicator())
                : goals.isEmpty
                    ? _EmptyVision(isFiltered: hasAnyGoal, onAdd: () => _showAddGoal(context))
                    : ListView.separated(
                        // Bottom padding keeps the last card clear of the FAB.
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.lg,
                          AppSpacing.gutter,
                          AppSpacing.xxxl + AppSpacing.xl,
                        ),
                        itemCount: goals.length,
                        separatorBuilder: (_, _) => AppSpacing.gapMd,
                        itemBuilder: (context, index) => VisionGoalCard(
                          goal: goals[index],
                          milestones: state.milestoneCounts[goals[index].id],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: hasAnyGoal
          ? FloatingActionButton.extended(
              onPressed: () => _showAddGoal(context),
              label: const Text(AppStrings.newGoal),
              icon: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _showAddGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const AddGoalSheet(),
    );
  }
}

/// Empty board (with a call to action) or "no matches" when filters hide
/// every goal.
class _EmptyVision extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onAdd;

  const _EmptyVision({required this.isFiltered, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(
              icon: isFiltered ? Icons.search_off_rounded : Icons.auto_awesome_rounded,
              color: isFiltered ? colors.surfaceContainerHigh : colors.primaryContainer,
              onColor: isFiltered ? colors.onSurfaceVariant : colors.onPrimaryContainer,
              filled: true,
              size: AppSpacing.xxxl,
            ),
            AppSpacing.gapLg,
            Text(
              isFiltered ? AppStrings.visionNoMatchesTitle : AppStrings.visionEmptyTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXs,
            Text(
              isFiltered ? AppStrings.visionNoMatchesMessage : AppStrings.visionEmptyMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...[
              AppSpacing.gapLg,
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text(AppStrings.addFirstGoal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
