import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/surface_card.dart';

const sleepGoodColor = AppColors.success;
const sleepShortColor = AppColors.warning;

/// Last seven nights as bars against a dashed goal line, with the weekly
/// average (and a warning when it's below the goal) in the header.
class SleepChartCard extends StatelessWidget {
  final Map<DateTime, Duration> nights;
  final Duration? average;
  final int goalHours;

  const SleepChartCard({super.key, required this.nights, required this.average, required this.goalHours});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final belowGoal = average != null && average! < Duration(hours: goalHours);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  AppStrings.sleepThisWeek,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(average == null ? AppStrings.noData : AppFormatters.duration(average!), style: theme.textTheme.titleMedium),
              Text(' ${AppStrings.sleepAvgPerNight}', style: theme.textTheme.bodySmall),
            ],
          ),
          if (belowGoal) ...[
            AppSpacing.gapXs,
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: AppSpacing.md, color: sleepShortColor),
                AppSpacing.hGapXs,
                Expanded(
                  child: Text(
                    '${AppStrings.sleepWeeklyWarningPrefix} $goalHours${AppStrings.sleepHoursShort} ${AppStrings.sleepWeeklyWarningSuffix}',
                    style: theme.textTheme.bodySmall?.copyWith(color: sleepShortColor),
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.gapMd,
          SizedBox(
            height: AppSpacing.chartHeightCompact,
            child: _SleepBars(nights: nights, goalHours: goalHours),
          ),
        ],
      ),
    );
  }
}

class _SleepBars extends StatelessWidget {
  final Map<DateTime, Duration> nights;
  final int goalHours;

  const _SleepBars({required this.nights, required this.goalHours});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final days = nights.keys.toList()..sort();
    final hours = [for (final d in days) nights[d]!.inMinutes / 60];
    final maxY = (math.max(goalHours.toDouble(), hours.fold<double>(0, math.max)) + 2).ceilToDouble();
    final axisStyle = theme.textTheme.labelSmall;

    return Semantics(
      label: [
        for (var i = 0; i < days.length; i++) '${DateFormat.E().format(days[i])} ${AppFormatters.duration(nights[days[i]]!)}',
      ].join(', '),
      excludeSemantics: true,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goalHours.toDouble(),
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: const [6, 6],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: axisStyle,
                  labelResolver: (_) => '${AppStrings.sleepGoal} $goalHours${AppStrings.sleepHoursShort}',
                ),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: AppSpacing.lg,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(DateFormat.E().format(days[i]).substring(0, 2), style: axisStyle),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colors.inverseSurface,
              tooltipBorderRadius: AppSpacing.borderRadiusMd,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                AppFormatters.duration(nights[days[group.x]]!),
                theme.textTheme.labelMedium!.copyWith(color: colors.onInverseSurface),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: hours[i],
                    width: AppSpacing.md,
                    color: hours[i] >= goalHours ? sleepGoodColor : sleepShortColor,
                    borderRadius: AppSpacing.borderRadiusSm,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
