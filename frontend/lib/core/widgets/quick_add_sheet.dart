import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_sheets.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_sheets.dart';

/// Opens the global Quick Add menu (from the lemon + in the nav bar).
Future<void> showQuickAddSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    builder: (sheetContext) => _QuickAddSheet(parentContext: context, ref: ref),
  );
}

class _QuickAddSheet extends StatelessWidget {
  /// The shell's context — used to open the follow-up sheet after this one
  /// closes, since the sheet's own context is gone by then.
  final BuildContext parentContext;
  final WidgetRef ref;

  const _QuickAddSheet({required this.parentContext, required this.ref});

  void _open(BuildContext sheetContext, Future<void> Function(BuildContext, WidgetRef, {VoidCallback? onSaved}) show) {
    Navigator.pop(sheetContext);
    show(parentContext, ref, onSaved: () => ref.read(dashboardControllerProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.quickAdd, style: theme.textTheme.titleLarge),
            AppSpacing.gapMd,
            _QuickAddOption(
              icon: Icons.receipt_long_rounded,
              color: AppColors.chartOrange,
              title: AppStrings.quickAddExpense,
              subtitle: AppStrings.quickAddExpenseHint,
              background: colors.surfaceContainerHigh,
              onTap: () => _open(context, showAddExpenseSheet),
            ),
            AppSpacing.gapSm,
            _QuickAddOption(
              icon: Icons.swap_horiz_rounded,
              color: AppColors.chartBlue,
              title: AppStrings.quickAddDebt,
              subtitle: AppStrings.quickAddDebtHint,
              background: colors.surfaceContainerHigh,
              onTap: () => _open(context, showAddTransactionSheet),
            ),
            AppSpacing.gapSm,
            _QuickAddOption(
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.chartGreen,
              title: AppStrings.quickAddTodo,
              subtitle: AppStrings.quickAddTodoHint,
              background: colors.surfaceContainerHigh,
              onTap: () => _open(context, showAddTodoSheet),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color background;
  final VoidCallback onTap;

  const _QuickAddOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      color: background,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md - 4),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
