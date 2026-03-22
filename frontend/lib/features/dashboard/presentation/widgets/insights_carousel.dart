import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';

class InsightsCarousel extends StatelessWidget {
  final List<SmartInsight> insights;
  
  const InsightsCarousel({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 90,
      child: PageView.builder(
        itemCount: insights.length,
        itemBuilder: (context, index) {
          final insight = insights[index];
          final color = switch (insight.type) {
            InsightType.positive => Colors.green,
            InsightType.warning => Colors.orange,
            _ => theme.colorScheme.primary,
          };
              
          return ChronicleCard(
            color: color.withValues(alpha: 0.05),
            hasBorder: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    insight.type == InsightType.positive ? Icons.auto_awesome_rounded : Icons.info_outline_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
