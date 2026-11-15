import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';

/// Three small tiles: learnings, places and moods logged in the period.
class ActivitySummaryRow extends StatelessWidget {
  final ActivitySummary summary;

  const ActivitySummaryRow({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActivityTile(
            icon: Icons.lightbulb_outline_rounded,
            color: AppColors.chartLemon,
            count: summary.newLearnings,
            label: AppStrings.learned,
            route: '/more/learnings',
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _ActivityTile(
            icon: Icons.place_outlined,
            color: AppColors.chartTeal,
            count: summary.placesVisited,
            label: AppStrings.places,
            route: '/more/places-visited',
          ),
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: _ActivityTile(
            icon: Icons.mood_rounded,
            color: AppColors.chartOrchid,
            count: summary.moodsLogged,
            label: AppStrings.moods,
            route: '/more/mood-board',
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final String route;

  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: () => context.push(route),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      child: Column(
        children: [
          IconBadge(icon: icon, color: color),
          AppSpacing.gapSm,
          Text('$count', style: theme.textTheme.headlineSmall),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
