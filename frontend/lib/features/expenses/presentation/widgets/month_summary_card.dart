import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';

/// Lemon hero for the viewed month: "Spent in November", the total, the
/// change vs last month, and two stat tiles (per day, non-essential).
/// Budgets live in their own section below.
class MonthSummaryCard extends StatelessWidget {
  final ExpenseState state;

  const MonthSummaryCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onPrimaryContainer;
    final count = state.viewMonthExpenses.length;

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppSpacing.borderRadiusXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.spentIn} ${AppFormatters.monthName(state.viewMonth)}',
                  style: theme.textTheme.titleSmall?.copyWith(color: ink),
                ),
              ),
              _ComparisonBadge(state: state),
            ],
          ),
          AppSpacing.gapXs,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.currency(state.viewMonthSpent),
              style: theme.textTheme.displayMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$count ${count == 1 ? AppStrings.expenseSingular : AppStrings.expensePlural}',
            style: theme.textTheme.bodySmall?.copyWith(color: ink.withValues(alpha: 0.7)),
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_today_rounded,
                  value: AppFormatters.currency(state.viewMonthDailyAverage),
                  label: AppStrings.perDayLower,
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.warning,
                  value: AppFormatters.currency(state.viewMonthNonEssential),
                  label: AppStrings.nonEssentialLower,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "↗ 18% vs Oct" pill; hidden when last month had no spending.
class _ComparisonBadge extends StatelessWidget {
  final ExpenseState state;

  const _ComparisonBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final previous = state.previousMonthSpent;
    if (previous <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final prevMonth = DateTime(state.viewMonth.year, state.viewMonth.month - 1);
    final change = (state.viewMonthSpent - previous) / previous;
    final pct = (change.abs() * 100).round();
    final icon = pct == 0
        ? Icons.trending_flat_rounded
        : (change > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded);
    final text = pct == 0
        ? '${AppStrings.sameAsLastMonth} ${AppFormatters.shortMonth(prevMonth)}'
        : '$pct% ${AppStrings.vs} ${AppFormatters.shortMonth(prevMonth)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 4, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: colors.onPrimaryContainer, borderRadius: AppSpacing.borderRadiusPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.md, color: colors.primaryContainer),
          AppSpacing.hGapXs,
          Text(text, style: theme.textTheme.labelMedium?.copyWith(color: colors.primaryContainer)),
        ],
      ),
    );
  }
}

/// Translucent tile on the lemon card: icon, value, label.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String value;
  final String label;

  const _StatTile({required this.icon, required this.value, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs, vertical: AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(color: ink.withValues(alpha: 0.07), borderRadius: AppSpacing.borderRadiusLg),
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.md + 2, color: iconColor ?? ink),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: theme.textTheme.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w700)),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.withValues(alpha: 0.75)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
