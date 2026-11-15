import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

/// Rounded surface panel — the base container for every card in the
/// revamped design. Optional [onTap] adds an ink ripple clipped to the shape.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingCard,
    this.onTap,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.borderRadiusXl;
    return Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
