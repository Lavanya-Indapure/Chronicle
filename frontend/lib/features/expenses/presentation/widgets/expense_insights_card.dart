import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';

class ExpenseInsightsCard extends StatelessWidget {
  final double unnecessarySpent;

  const ExpenseInsightsCard({
    super.key,
    required this.unnecessarySpent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Colors.amber;

    return ChronicleCard(
      color: color.withValues(alpha: 0.05),
      hasBorder: true,
      borderColor: color.withValues(alpha: 0.2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: color, size: 24),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Savings Insight', 
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                  )
                ),
                Text(
                  'You could have saved ₹${unnecessarySpent.toInt()} this period!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
