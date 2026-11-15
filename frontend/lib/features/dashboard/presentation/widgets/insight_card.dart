import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';

/// Small tile with a coloured icon and a one/two-line insight message.
class InsightCard extends StatelessWidget {
  final SmartInsight insight;

  const InsightCard({super.key, required this.insight});

  (IconData, Color) get _style => switch (insight.type) {
        InsightType.positive => (Icons.trending_up_rounded, AppColors.success),
        InsightType.warning => (Icons.warning_amber_rounded, AppColors.warning),
        InsightType.neutral => (Icons.lightbulb_outline_rounded, AppColors.chartBlue),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _style;
    return SizedBox(
      width: AppSpacing.insightCardWidth,
      child: SurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: icon, color: color, size: AppSpacing.xl + 4),
            const Spacer(),
            Text(
              insight.message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
