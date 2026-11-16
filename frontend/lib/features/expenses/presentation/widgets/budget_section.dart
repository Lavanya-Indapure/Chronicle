import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/expenses/domain/budget_status.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';

/// "Budgets" header + weekly and monthly tiles side by side (monthly only
/// when looking at a past month). Unset budgets show a "Set …" tile.
class BudgetSection extends StatelessWidget {
  final BudgetStatus? weekly;
  final BudgetStatus? monthly;

  /// Past months only have a monthly budget to show.
  final bool showWeekly;

  /// "Oct" when a past month is viewed, for the header.
  final DateTime? pastMonth;

  final ValueChanged<BudgetType> onEdit;

  const BudgetSection({
    super.key,
    required this.weekly,
    required this.monthly,
    required this.showWeekly,
    required this.onEdit,
    this.pastMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthlyTile = monthly == null
        ? _SetBudgetTile(label: AppStrings.setMonthlyBudgetCta, onTap: () => onEdit(BudgetType.monthly))
        : BudgetTile(status: monthly!, onTap: () => onEdit(BudgetType.monthly));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: pastMonth == null
              ? AppStrings.budgets
              : '${AppStrings.budgetFor} ${AppFormatters.monthName(pastMonth!)}',
          compact: true,
        ),
        AppSpacing.gapSm,
        if (showWeekly)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: weekly == null
                      ? _SetBudgetTile(label: AppStrings.setWeeklyBudgetCta, onTap: () => onEdit(BudgetType.weekly))
                      : BudgetTile(status: weekly!, onTap: () => onEdit(BudgetType.weekly)),
                ),
                AppSpacing.hGapSm,
                Expanded(child: monthlyTile),
              ],
            ),
          )
        else
          monthlyTile,
      ],
    );
  }
}

/// One budget: spent of total, a bar with a tick for "where you should be
/// by today", and what's left per day. Tap to change the amount.
class BudgetTile extends StatelessWidget {
  final BudgetStatus status;
  final VoidCallback onTap;

  const BudgetTile({super.key, required this.status, required this.onTap});

  static Color colorFor(BudgetPace pace) => switch (pace) {
        BudgetPace.onTrack => AppColors.success,
        BudgetPace.ahead => AppColors.warning,
        BudgetPace.over => AppColors.error,
      };

  String get _title => status.type == BudgetType.weekly ? AppStrings.weekly : AppStrings.monthly;

  /// Headline status: "₹1,900 left" / "Spending fast" / "Over by ₹200".
  String get _status {
    final s = status;
    if (s.isOver) return '${AppStrings.budgetOverBy} ${AppFormatters.currency(-s.left)}';
    if (s.isFinished) return '${AppFormatters.currency(s.left)} ${AppStrings.budgetUnderBy}';
    if (s.pace == BudgetPace.ahead) return AppStrings.budgetSpendingFast;
    return '${AppFormatters.currency(s.left)} ${AppStrings.left}';
  }

  /// Detail: "₹475/day · 4 days left" while the period runs.
  String? get _detail {
    final s = status;
    final perDay = s.perDayLeft;
    if (perDay == null) return null;
    final days = '${s.daysLeft} ${s.daysLeft == 1 ? AppStrings.dayLeftSuffix : AppStrings.daysLeftSuffix}';
    return '${AppFormatters.currency(perDay)}${AppStrings.perDaySuffix} · $days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final s = status;
    final color = colorFor(s.pace);

    return Semantics(
      button: true,
      label: '$_title ${AppStrings.budgetLower}: ${AppFormatters.currency(s.spent)} ${AppStrings.of} '
          '${AppFormatters.currency(s.budget)}. $_status. ${_detail ?? ''}',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        padding: AppSpacing.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(_title, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant))),
                Icon(Icons.edit_outlined, size: AppSpacing.md, color: colors.onSurfaceVariant),
              ],
            ),
            AppSpacing.gapXs,
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: AppFormatters.currency(s.spent),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: s.isOver ? color : null),
                  children: [
                    TextSpan(
                      text: ' / ${AppFormatters.compactCurrency(s.budget)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapSm,
            _PaceBar(fraction: s.fraction, marker: s.isFinished ? null : s.elapsed, color: color),
            AppSpacing.gapSm,
            Text(
              _status,
              style: theme.textTheme.labelMedium?.copyWith(
                color: s.pace == BudgetPace.onTrack ? colors.onSurface : color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_detail != null)
              Text(_detail!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// Progress bar with an optional thin tick at [marker] (share of the period
/// gone) — fill past the tick means spending faster than time is passing.
class _PaceBar extends StatelessWidget {
  final double fraction;
  final double? marker;
  final Color color;

  const _PaceBar({required this.fraction, required this.marker, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const height = AppSpacing.progressBarHeight;
    // No LayoutBuilder: the tiles sit in an IntrinsicHeight row, which can't
    // measure one. Align places the tick by fraction instead.
    return SizedBox(
      height: height + AppSpacing.xs * 2,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusPill,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: height,
                color: color,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
          ),
          if (marker != null)
            Align(
              alignment: Alignment(marker!.clamp(0.0, 1.0) * 2 - 1, 0),
              child: Container(
                width: 2,
                decoration: BoxDecoration(color: colors.onSurface, borderRadius: AppSpacing.borderRadiusPill),
              ),
            ),
        ],
      ),
    );
  }
}

class _SetBudgetTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SetBudgetTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SurfaceCard(
      onTap: onTap,
      padding: AppSpacing.paddingAll,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: colors.primary),
            AppSpacing.gapXs,
            Text(label, style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
