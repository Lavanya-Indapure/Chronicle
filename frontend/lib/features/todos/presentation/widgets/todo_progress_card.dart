import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/percent_ring.dart';

/// Lemon hero card: "Today's Progress · 5 of 15 done" with a big ring.
class TodoProgressCard extends StatelessWidget {
  final int completed;
  final int total;

  const TodoProgressCard({super.key, required this.completed, required this.total});

  String get _message {
    final remaining = total - completed;
    if (total > 0 && remaining == 0) return AppStrings.allDoneToday;
    if (completed == 0) return AppStrings.nothingStarted;
    return remaining == 1
        ? '$remaining ${AppStrings.todoLeftSuffix}'
        : '$remaining ${AppStrings.todosLeftSuffix}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onPrimaryContainer;

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppSpacing.borderRadiusXxl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.todayProgress, style: theme.textTheme.titleSmall?.copyWith(color: ink)),
                AppSpacing.gapXs,
                Text.rich(
                  TextSpan(
                    text: '$completed',
                    style: theme.textTheme.displayMedium?.copyWith(color: ink),
                    children: [
                      TextSpan(
                        text: ' ${AppStrings.doneOf} $total ${AppStrings.doneSuffix}',
                        style: theme.textTheme.titleMedium?.copyWith(color: ink),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapXs,
                Text(_message, style: theme.textTheme.bodyMedium?.copyWith(color: ink)),
              ],
            ),
          ),
          AppSpacing.hGapMd,
          PercentRing(
            fraction: total == 0 ? 0 : completed / total,
            color: ink,
            size: AppSpacing.ringSizeLg,
            strokeWidth: AppSpacing.ringStrokeLg,
            trackColor: ink.withValues(alpha: 0.12),
            labelStyle: theme.textTheme.titleSmall?.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}
