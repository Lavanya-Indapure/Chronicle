import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

class ActivityStatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const ActivityStatItem({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Icon(
            icon, 
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          count.toString(), 
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          )
        ),
        Text(
          label, 
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          )
        ),
      ],
    );
  }
}
