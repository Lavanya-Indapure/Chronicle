import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';

class BudgetCard extends StatelessWidget {
  final String title;
  final double budget;
  final double spent;
  final Color color;
  final VoidCallback onSet;

  const BudgetCard({
    super.key,
    required this.title,
    required this.budget,
    required this.spent,
    required this.color,
    required this.onSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > budget && budget > 0;
    final displayColor = isOver ? theme.colorScheme.error : color;

    return ChronicleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                )
              ),
              IconButton(
                icon: Icon(Icons.edit_rounded, size: 16, color: theme.colorScheme.primary),
                onPressed: onSet,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget > 0 ? '₹${spent.toInt()} / ₹${budget.toInt()}' : 'No budget set',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isOver ? theme.colorScheme.error : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    budget > 0 ? 'Spent of limit' : 'Tap edit to set goal',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (budget > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: displayColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: displayColor,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.gapLg,
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: displayColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                ),
              ),
            ],
          ),
          if (isOver) ...[
            AppSpacing.gapSm,
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 14),
                AppSpacing.hGapXs,
                Text(
                  'Over budget by ₹${(spent - budget).toInt()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
