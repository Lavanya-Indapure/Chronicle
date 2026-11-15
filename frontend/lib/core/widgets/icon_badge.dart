import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

/// Circular icon holder. With [filled] the circle takes [color] and the icon
/// is drawn in [onColor]; otherwise the circle is a dark/neutral well and the
/// icon takes [color] (as in the reference's category tiles).
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? onColor;
  final bool filled;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.onColor,
    this.filled = false,
    this.size = AppSpacing.iconBadgeSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : colors.surfaceContainerLowest,
      ),
      child: Icon(icon, size: size * 0.5, color: filled ? (onColor ?? colors.surface) : color),
    );
  }
}
