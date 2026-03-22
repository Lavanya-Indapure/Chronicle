import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';

class DebtCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const DebtCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ChronicleCard(
      color: color.withValues(alpha: 0.05),
      hasBorder: true,
      borderColor: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          AppSpacing.gapMd,
          Text(
            title, 
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            )
          ),
          AppSpacing.gapXs,
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
