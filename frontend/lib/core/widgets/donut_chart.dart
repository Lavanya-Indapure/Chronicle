import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

/// One coloured arc of a [DonutChart].
class DonutSegment {
  final double value;
  final Color color;

  const DonutSegment({required this.value, required this.color});
}

/// Ring chart with rounded, gapped segments and a faint tick halo, with
/// [center] drawn in the middle. Animates in on first build.
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final Widget center;
  final double size;
  final double strokeWidth;

  const DonutChart({
    super.key,
    required this.segments,
    required this.center,
    this.size = AppSpacing.donutSize,
    this.strokeWidth = AppSpacing.donutStroke,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => CustomPaint(
          painter: _DonutPainter(
            segments: segments,
            strokeWidth: strokeWidth,
            progress: progress,
            trackColor: colors.surfaceContainerHigh,
            tickColor: colors.onSurfaceVariant.withValues(alpha: 0.25),
          ),
          child: child,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final double progress;
  final Color trackColor;
  final Color tickColor;

  _DonutPainter({
    required this.segments,
    required this.strokeWidth,
    required this.progress,
    required this.trackColor,
    required this.tickColor,
  });

  static const _tickCount = 120;
  static const _tickLength = 7.0;
  static const _haloGap = 10.0; // space between ticks and the ring
  static const _segmentGap = 0.16; // radians between segments

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;

    // Tick halo
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _tickCount; i++) {
      final angle = 2 * math.pi * i / _tickCount;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + dir * (outer - _tickLength), center + dir * outer, tickPaint);
    }

    // Ring
    final radius = outer - _tickLength - _haloGap - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) {
      canvas.drawArc(rect, 0, 2 * math.pi, false, ringPaint..color = trackColor);
      return;
    }

    final visible = segments.where((s) => s.value > 0).toList();
    final gap = visible.length > 1 ? _segmentGap : 0.0;
    final available = 2 * math.pi - gap * visible.length;
    var start = -math.pi / 2;
    for (final s in visible) {
      final sweep = available * (s.value / total) * progress;
      // Keep tiny segments visible as a dot.
      canvas.drawArc(rect, start + gap / 2, math.max(sweep, 0.001), false, ringPaint..color = s.color);
      start += available * (s.value / total) + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.segments != segments ||
      old.trackColor != trackColor ||
      old.tickColor != tickColor;
}
