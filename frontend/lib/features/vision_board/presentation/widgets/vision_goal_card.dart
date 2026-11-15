import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';

/// Label + colour for a goal's status string.
(String, Color) goalStatusStyle(String status, ColorScheme colors) => switch (status) {
      'completed' => (AppStrings.statusCompleted, AppColors.success),
      'in_progress' => (AppStrings.statusInProgress, AppColors.info),
      _ => (AppStrings.statusNotStarted, colors.onSurfaceVariant),
    };

/// Goal summary card: category + favourite, title, progress bar, deadline
/// and status. Tapping opens the goal's details.
class VisionGoalCard extends StatelessWidget {
  final VisionGoal goal;

  const VisionGoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (statusLabel, statusColor) = goalStatusStyle(goal.status, colors);
    final progress = (goal.progress / 100).clamp(0.0, 1.0);

    return SurfaceCard(
      onTap: () => context.push('/more/vision-board/details', extra: goal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (goal.category != null || goal.isFavorite) ...[
            Row(
              children: [
                if (goal.category != null) _Tag(text: goal.category!, color: colors.primary),
                const Spacer(),
                if (goal.isFavorite) const Icon(Icons.favorite_rounded, color: AppColors.error, size: AppSpacing.md + 2),
              ],
            ),
            AppSpacing.gapMd,
          ],
          Text(goal.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (goal.description?.trim().isNotEmpty ?? false) ...[
            AppSpacing.gapXs,
            Text(goal.description!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppSpacing.borderRadiusPill,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: AppSpacing.progressBarHeight,
                    color: statusColor,
                    backgroundColor: colors.surfaceContainerLowest,
                  ),
                ),
              ),
              AppSpacing.hGapMd,
              Text('${goal.progress}%', style: theme.textTheme.labelMedium),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: AppSpacing.md, color: colors.onSurfaceVariant),
              AppSpacing.hGapXs,
              Expanded(
                child: Text(
                  goal.targetDate != null ? DateFormat('MMM yyyy').format(goal.targetDate!) : AppStrings.noDeadline,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              _Tag(text: statusLabel, color: statusColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs / 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppSpacing.borderRadiusPill),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
