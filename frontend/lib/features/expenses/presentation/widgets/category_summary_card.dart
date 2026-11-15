import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/donut_chart.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/expenses/domain/models/category_spend.dart';
import 'package:chronicle/features/expenses/presentation/widgets/category_visuals.dart';

/// Compact "where it went": small ring beside the top categories, with a
/// link to the full breakdown.
class CategorySummaryCard extends StatelessWidget {
  final List<CategorySpend> breakdown;
  final VoidCallback onSeeAll;

  const CategorySummaryCard({super.key, required this.breakdown, required this.onSeeAll});

  static const _maxRows = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = breakdown.take(_maxRows).toList();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.whereItWent, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          AppSpacing.gapMd,
          Row(
            children: [
              DonutChart(
                size: AppSpacing.donutSizeSm,
                strokeWidth: AppSpacing.donutStrokeSm,
                segments: [
                  for (var i = 0; i < breakdown.length; i++)
                    DonutSegment(value: breakdown[i].amount, color: CategoryVisuals.colorAt(i)),
                ],
                center: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary, size: AppSpacing.lg),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < top.length; i++) ...[
                      if (i > 0) AppSpacing.gapSm,
                      _LegendRow(spend: top[i], color: CategoryVisuals.colorAt(i)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSeeAll,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded),
              label: Text(
                breakdown.length > _maxRows
                    ? '${AppStrings.allCategories} (${breakdown.length})'
                    : AppStrings.allCategories,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "● Rent ........ ₹12,000 / 72%"
class _LegendRow extends StatelessWidget {
  final CategorySpend spend;
  final Color color;

  const _LegendRow({required this.spend, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: AppSpacing.accentDotSize + 2,
          height: AppSpacing.accentDotSize + 2,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spend.name ?? AppStrings.uncategorized,
                style: theme.textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(AppFormatters.percent(spend.share), style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        Text(AppFormatters.currency(spend.amount), style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
