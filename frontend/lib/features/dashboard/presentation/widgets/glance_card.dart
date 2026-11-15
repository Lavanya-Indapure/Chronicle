import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/surface_card.dart';

/// Compact stat tile for the dashboard's 2×2 "Your Day" grid.
/// Width comes from the parent; height is fixed so tiles line up.
class GlanceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String caption;
  final VoidCallback? onTap;

  const GlanceCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: AppSpacing.glanceTileHeight,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: icon, color: color, size: AppSpacing.xl),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(label, style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text(caption, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
