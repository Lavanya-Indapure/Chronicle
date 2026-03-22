import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

/// A premium card widget for the Chronicle design system.
/// Features a subtle border and consistent padding/radius.
class ChronicleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final double? borderRadius;
  final bool hasBorder;
  final VoidCallback? onTap;

  const ChronicleCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderRadius,
    this.hasBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget current = Container(
      padding: padding ?? AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
        border: hasBorder
            ? Border.all(
                color: borderColor ?? theme.colorScheme.outline,
                width: 1,
              )
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      current = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
        child: current,
      );
    }

    return margin != null
        ? Padding(
            padding: margin!,
            child: current,
          )
        : current;
  }
}
