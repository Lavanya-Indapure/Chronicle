import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/vision_board/domain/milestone_progress.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/milestones_controller.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';
import 'package:chronicle/features/vision_board/presentation/widgets/add_goal_sheet.dart';
import 'package:chronicle/features/vision_board/presentation/widgets/milestones_section.dart';
import 'package:chronicle/features/vision_board/presentation/widgets/vision_goal_card.dart';

class VisionGoalDetailsScreen extends ConsumerWidget {
  /// The goal as it was when opened; the live copy from the board is shown
  /// when available so progress/status updates appear immediately.
  final VisionGoal goal;

  const VisionGoalDetailsScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(visionBoardControllerProvider.select((s) => s.goalById(goal.id))) ?? goal;
    final milestones = ref.watch(milestonesProvider(goal.id));
    final fromMilestones = milestones.items.isNotEmpty;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.visionGoalDetailsTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.favoritesOnly,
            icon: Icon(
              live.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: live.isFavorite ? AppColors.error : null,
            ),
            onPressed: () => ref.read(visionBoardControllerProvider.notifier).toggleFavorite(live),
          ),
          IconButton(
            tooltip: AppStrings.visionEditGoal,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editGoal(context, live, progressFromMilestones: fromMilestones),
          ),
          IconButton(
            tooltip: AppStrings.delete,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () => _deleteGoal(context, ref, live),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxl),
        children: [
          if (live.category != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text(live.category!.toUpperCase())),
            ),
            AppSpacing.gapSm,
          ],
          Text(live.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (live.description?.trim().isNotEmpty ?? false) ...[
            AppSpacing.gapSm,
            Text(live.description!, style: theme.textTheme.bodyLarge),
          ],
          AppSpacing.gapLg,
          _ProgressCard(goal: live, milestones: fromMilestones ? milestones.count.total : 0, done: milestones.count.done),
          AppSpacing.gapMd,
          _DurationCard(goal: live),
          AppSpacing.gapLg,
          MilestonesSection(goal: live),
          AppSpacing.gapLg,
          const SectionHeader(title: AppStrings.visionPlanTitle, compact: true),
          AppSpacing.gapSm,
          SurfaceCard(
            child: Text(
              live.plan?.trim().isNotEmpty ?? false ? live.plan! : AppStrings.visionNoPlan,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: live.plan?.trim().isNotEmpty ?? false ? null : colors.onSurfaceVariant,
              ),
            ),
          ),
          if (live.status == GoalStatus.completed) ...[
            AppSpacing.gapXl,
            Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: AppSpacing.xxxl),
                AppSpacing.gapSm,
                Text(
                  AppStrings.visionGoalAchieved,
                  style: theme.textTheme.titleLarge?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _editGoal(BuildContext context, VisionGoal goal, {required bool progressFromMilestones}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddGoalSheet(goal: goal, progressFromMilestones: progressFromMilestones),
    );
  }

  Future<void> _deleteGoal(BuildContext context, WidgetRef ref, VisionGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.visionDeleteGoalTitle),
        content: const Text(AppStrings.visionDeleteGoalMessage),
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

    if (confirmed == true) {
      await ref.read(visionBoardControllerProvider.notifier).deleteGoal(goal.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

/// Big percentage + bar, with where the number comes from.
class _ProgressCard extends StatelessWidget {
  final VisionGoal goal;
  final int milestones;
  final int done;

  const _ProgressCard({required this.goal, required this.milestones, required this.done});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (statusLabel, statusColor) = goalStatusStyle(goal.status, colors);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${goal.progress}%', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
              AppSpacing.hGapSm,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(AppStrings.visionProgressLabel, style: theme.textTheme.bodyMedium),
                ),
              ),
              Flexible(
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelLarge?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusPill,
            child: LinearProgressIndicator(
              value: (goal.progress / 100).clamp(0.0, 1.0),
              minHeight: AppSpacing.progressBarHeight,
              color: statusColor,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            milestones > 0
                ? '${AppStrings.visionProgressFromPrefix} $done ${AppStrings.visionMilestonesOf} $milestones ${AppStrings.visionProgressFromSuffix}'
                : AppStrings.visionProgressManualHint,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final VisionGoal goal;

  const _DurationCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysRemaining = goal.targetDate?.difference(DateTime.now()).inDays ?? 0;
    final target = goal.targetDate;

    return SurfaceCard(
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppStrings.visionTimeline}: ${goal.duration}', style: theme.textTheme.titleSmall),
                Text(
                  target == null
                      ? AppStrings.noDeadline
                      : '${AppStrings.visionTarget}: ${DateFormat('MMMM yyyy').format(target)} · '
                          '${daysRemaining > 0 ? '$daysRemaining ${AppStrings.visionDaysLeft}' : AppStrings.visionTimeUp}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
