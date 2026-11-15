import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';

/// All insights stacked in one card, one row each.
class InsightsCard extends StatelessWidget {
  final List<SmartInsight> insights;

  const InsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).colorScheme.outline;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < insights.length; i++) ...[
            if (i > 0) Divider(height: 1, color: divider, indent: AppSpacing.xl + AppSpacing.md),
            _InsightRow(insight: insights[i]),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final SmartInsight insight;

  const _InsightRow({required this.insight});

  (IconData, Color) get _style => switch (insight.type) {
        InsightType.positive => (Icons.trending_up_rounded, AppColors.success),
        InsightType.warning => (Icons.warning_amber_rounded, AppColors.warning),
        InsightType.neutral => (Icons.lightbulb_outline_rounded, AppColors.chartBlue),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _style;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - 4),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: AppSpacing.xl),
          AppSpacing.hGapMd,
          Expanded(
            child: Text(
              insight.message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
