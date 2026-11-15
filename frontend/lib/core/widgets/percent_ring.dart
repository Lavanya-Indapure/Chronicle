import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/utils/formatters.dart';

/// Small progress ring with the percentage printed in the middle.
class PercentRing extends StatelessWidget {
  final double fraction; // 0.0 – 1.0
  final Color color;
  final double size;
  final double strokeWidth;

  const PercentRing({
    super.key,
    required this.fraction,
    required this.color,
    this.size = AppSpacing.ringSizeSm,
    this.strokeWidth = AppSpacing.ringStrokeSm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = fraction.clamp(0.0, 1.0);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => SizedBox.square(
              dimension: size,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerLowest,
              ),
            ),
          ),
          Text(
            AppFormatters.percent(value),
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
