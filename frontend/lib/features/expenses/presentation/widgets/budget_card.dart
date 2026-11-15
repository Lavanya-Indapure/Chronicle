import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/percent_ring.dart';
import 'package:chronicle/core/widgets/surface_card.dart';

/// Budget vs. spent for one period, with a ring and a progress bar.
class BudgetCard extends StatelessWidget {
  final String title;
  final double budget;
  final double spent;
  final Color color;
  final VoidCallback onEdit;

  const BudgetCard({
    super.key,
    required this.title,
    required this.budget,
    required this.spent,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBudget = budget > 0;
    final fraction = hasBudget ? spent / budget : 0.0;
    final isOver = hasBudget && spent > budget;
    final barColor = isOver ? AppColors.error : color;

    return SurfaceCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              Icon(Icons.edit_outlined, size: AppSpacing.md + 2, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasBudget ? AppFormatters.currency(spent) : AppStrings.noBudgetSet,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOver ? AppColors.error : null,
                      ),
                    ),
                    if (hasBudget)
                      Text(
                        isOver
                            ? '${AppStrings.overBudgetBy} ${AppFormatters.currency(spent - budget)}'
                            : '${AppFormatters.currency(budget - spent)} ${AppStrings.left} · '
                                '${AppStrings.of} ${AppFormatters.currency(budget)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: isOver ? AppColors.error : null),
                      )
                    else
                      Text(AppStrings.setBudget, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (hasBudget) PercentRing(fraction: fraction, color: barColor),
            ],
          ),
          if (hasBudget) ...[
            AppSpacing.gapMd,
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusPill,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: AppSpacing.progressBarHeight,
                  color: barColor,
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
