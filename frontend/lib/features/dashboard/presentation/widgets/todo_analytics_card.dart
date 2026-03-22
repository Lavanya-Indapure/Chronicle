import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';

class TodoAnalyticsCard extends StatelessWidget {
  final TodoAnalytics analytics;
  
  const TodoAnalyticsCard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChronicleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tasks & Streaks", 
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            )
          ),
          AppSpacing.gapLg,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: "Completed", 
                value: "${analytics.completedTasks}/${analytics.totalTasks}", 
                icon: Icons.check_circle_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              _StatItem(
                label: "Streak", 
                value: "${analytics.currentStreak}d", 
                icon: Icons.local_fire_department_rounded,
                color: Colors.orange,
              ),
              _StatItem(
                label: "Best", 
                value: "${analytics.bestStreak}d", 
                icon: Icons.emoji_events_outlined,
                color: Colors.amber,
              ),
            ],
          ),
          AppSpacing.gapLg,
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: analytics.totalTasks == 0 ? 0 : analytics.completionPercentage / 100,
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${analytics.completionPercentage.toStringAsFixed(0)}% Completed",
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                "Keep it up!",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label, 
    required this.value, 
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        AppSpacing.gapXs,
        Text(
          value, 
          style: theme.textTheme.titleLarge?.copyWith(
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
