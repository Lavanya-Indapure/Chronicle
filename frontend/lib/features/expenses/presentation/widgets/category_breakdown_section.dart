import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/donut_chart.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/percent_ring.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/expenses/domain/models/category_spend.dart';
import 'package:chronicle/features/expenses/presentation/widgets/category_visuals.dart';

/// Donut of this month's spending by category, with a 2-column grid of
/// category tiles underneath.
class CategoryBreakdownSection extends StatelessWidget {
  final List<CategorySpend> breakdown;
  final double total;
  final DateTime month;

  /// Tapping a category tile (e.g. to list its expenses).
  final ValueChanged<CategorySpend>? onCategoryTap;

  const CategoryBreakdownSection({
    super.key,
    required this.breakdown,
    required this.total,
    required this.month,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (breakdown.isEmpty) {
      return SurfaceCard(
        child: Center(child: Text(AppStrings.noExpensesThisMonth, style: theme.textTheme.bodyMedium)),
      );
    }

    return Column(
      children: [
        DonutChart(
          segments: [
            for (var i = 0; i < breakdown.length; i++)
              DonutSegment(value: breakdown[i].amount, color: CategoryVisuals.colorAt(i)),
          ],
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary),
              AppSpacing.gapSm,
              Text(AppFormatters.currency(total), style: theme.textTheme.headlineSmall),
              Text(AppFormatters.monthYear(month), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        AppSpacing.gapLg,
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < breakdown.length; i++)
                  SizedBox(
                    width: tileWidth,
                    child: _CategoryTile(
                      spend: breakdown[i],
                      color: CategoryVisuals.colorAt(i),
                      // Uncategorised spend can't be filtered on, so it isn't tappable.
                      onTap: onCategoryTap == null || breakdown[i].categoryId == null
                          ? null
                          : () => onCategoryTap!(breakdown[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategorySpend spend;
  final Color color;
  final VoidCallback? onTap;

  const _CategoryTile({required this.spend, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = spend.count == 1 ? AppStrings.transactionSuffix : AppStrings.transactionsSuffix;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: CategoryVisuals.iconFor(spend.name), color: color, size: AppSpacing.xl + 4),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spend.name ?? AppStrings.uncategorized,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${spend.count} $countLabel',
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '-${AppFormatters.currency(spend.amount)}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              AppSpacing.hGapXs,
              PercentRing(fraction: spend.share, color: color),
            ],
          ),
        ],
      ),
    );
  }
}
