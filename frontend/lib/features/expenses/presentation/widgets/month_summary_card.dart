import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';

/// Lemon card for the viewed month: total + change vs last month, budget
/// bars (current month only — tap to manage budgets), then daily average and
/// non-essential spend.
class MonthSummaryCard extends StatelessWidget {
  final ExpenseState state;
  final VoidCallback onManageBudgets;

  const MonthSummaryCard({super.key, required this.state, required this.onManageBudgets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onPrimaryContainer;
    final showBudgets = state.isViewingCurrentMonth;
    final monthly = state.currentMonthlyBudget;
    final weekly = state.currentWeeklyBudget;

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppSpacing.borderRadiusXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.spentLabel, style: theme.textTheme.titleSmall?.copyWith(color: ink)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppFormatters.currency(state.viewMonthSpent),
                        style: theme.textTheme.displayMedium?.copyWith(color: ink),
                      ),
                    ),
                  ],
                ),
              ),
              _ComparisonBadge(state: state),
            ],
          ),
          if (showBudgets) ...[
            AppSpacing.gapMd,
            if (monthly <= 0 && weekly <= 0)
              _SetBudgetLink(onTap: onManageBudgets)
            else ...[
              if (monthly > 0)
                _BudgetBar(label: AppStrings.monthly, spent: state.spentThisMonth, budget: monthly, onTap: onManageBudgets),
              if (monthly > 0 && weekly > 0) AppSpacing.gapSm,
              if (weekly > 0)
                _BudgetBar(label: AppStrings.weekly, spent: state.spentThisWeek, budget: weekly, onTap: onManageBudgets),
            ],
          ],
          AppSpacing.gapMd,
          Divider(height: 1, color: ink.withValues(alpha: 0.12)),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(child: _InlineStat(value: AppFormatters.currency(state.viewMonthDailyAverage), label: AppStrings.dailyAvgLower)),
              Expanded(
                child: _InlineStat(
                  value: AppFormatters.currency(state.viewMonthNonEssential),
                  label: AppStrings.nonEssentialLower,
                  dotColor: AppColors.warning,
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

/// "Monthly ▓▓▓▓░░ ₹8,261 left ›" — tap to manage budgets.
class _BudgetBar extends StatelessWidget {
  final String label;
  final double spent;
  final double budget;
  final VoidCallback onTap;

  const _BudgetBar({required this.label, required this.spent, required this.budget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;
    final over = spent > budget;
    final status = over
        ? '${AppStrings.budgetOverPrefix} ${AppFormatters.currency(spent - budget)}'
        : '${AppFormatters.currency(budget - spent)} ${AppStrings.budgetLeftSuffix} ${AppFormatters.currency(budget)}';
    final statusColor = over ? AppColors.error : ink;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: ink)),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: AppSpacing.md, color: ink),
              ],
            ),
            AppSpacing.gapXs,
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusPill,
              child: LinearProgressIndicator(
                value: (spent / budget).clamp(0.0, 1.0),
                minHeight: AppSpacing.progressBarHeight - 2,
                color: over ? AppColors.error : ink,
                backgroundColor: ink.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetBudgetLink extends StatelessWidget {
  final VoidCallback onTap;

  const _SetBudgetLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: AppSpacing.md + 2, color: ink),
            AppSpacing.hGapXs,
            Text(AppStrings.setBudgetCta, style: theme.textTheme.labelLarge?.copyWith(color: ink)),
            Icon(Icons.chevron_right_rounded, size: AppSpacing.md + 2, color: ink),
          ],
        ),
      ),
    );
  }
}

/// "₹1,116 daily avg" on one line.
class _InlineStat extends StatelessWidget {
  final String value;
  final String label;
  final Color? dotColor;

  const _InlineStat({required this.value, required this.label, this.dotColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;
    return Row(
      children: [
        if (dotColor != null) ...[
          Container(
            width: AppSpacing.accentDotSize,
            height: AppSpacing.accentDotSize,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          AppSpacing.hGapXs,
        ],
        Flexible(
          child: Text.rich(
            TextSpan(
              text: value,
              style: theme.textTheme.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: ' $label', style: theme.textTheme.bodySmall?.copyWith(color: ink)),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
