import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';

/// Accent colour per recurrence group (dot, check fill, progress).
extension RecurrenceAccent on RecurrenceType {
  Color get accent => switch (this) {
        RecurrenceType.daily => AppColors.chartBlue,
        RecurrenceType.weekly => AppColors.chartOrchid,
        RecurrenceType.monthly => AppColors.chartOrange,
        RecurrenceType.none => AppColors.chartTeal,
      };
}

/// Section header: "● Daily ................ 3/9".
class TodoGroupHeader extends StatelessWidget {
  final RecurrenceType type;
  final int completed;
  final int total;

  const TodoGroupHeader({
    super.key,
    required this.type,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = completed == total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: AppSpacing.accentDotSize,
            height: AppSpacing.accentDotSize,
            decoration: BoxDecoration(color: type.accent, shape: BoxShape.circle),
          ),
          AppSpacing.hGapSm,
          Expanded(child: Text(type.label, style: theme.textTheme.titleMedium)),
          Text(
            '$completed/$total',
            style: theme.textTheme.labelMedium?.copyWith(
              color: done ? AppColors.success : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
