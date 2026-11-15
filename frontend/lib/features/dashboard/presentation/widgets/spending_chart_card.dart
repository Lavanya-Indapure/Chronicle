import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';

/// "Avg. monthly expenses"-style card: headline figure + daily line chart.
class SpendingChartCard extends StatelessWidget {
  final ExpenseAnalytics analytics;

  const SpendingChartCard({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTrend = analytics.chartData.length >= 2;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.dailySpending, style: theme.textTheme.bodyMedium),
          AppSpacing.gapXs,
          Text(
            AppFormatters.currency(analytics.averageDaily),
            style: theme.textTheme.headlineLarge,
          ),
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: AppSpacing.md, color: AppColors.success),
              AppSpacing.hGapXs,
              Text(AppStrings.averagePerDay, style: theme.textTheme.bodySmall),
            ],
          ),
          AppSpacing.gapLg,
          SizedBox(
            height: AppSpacing.chartHeight,
            child: hasTrend
                ? _SpendingLineChart(chartData: analytics.chartData)
                : Center(child: Text(AppStrings.notEnoughData, style: theme.textTheme.bodySmall)),
          ),
        ],
      ),
    );
  }
}

class _SpendingLineChart extends StatelessWidget {
  final Map<String, double> chartData;

  const _SpendingLineChart({required this.chartData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final keys = chartData.keys.toList()..sort();
    final dates = keys.map(DateTime.parse).toList();
    final spots = [for (var i = 0; i < keys.length; i++) FlSpot(i.toDouble(), chartData[keys[i]]!)];
    final maxY = spots.map((s) => s.y).fold<double>(0, math.max);
    final yInterval = maxY > 0 ? maxY / 3 : 1.0;
    final xInterval = (keys.length / 5).ceilToDouble().clamp(1.0, double.infinity);
    final axisStyle = theme.textTheme.labelSmall;
    const lineColor = AppColors.chartBlue;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (keys.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.25,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.onSurfaceVariant.withValues(alpha: 0.25),
            strokeWidth: 1,
            dashArray: const [6, 6],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: AppSpacing.xxl,
              interval: yInterval,
              getTitlesWidget: (value, meta) => value == meta.max
                  ? const SizedBox.shrink()
                  : Text(AppFormatters.compactCurrency(value), style: axisStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: AppSpacing.xl,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                // fl_chart always adds a label at maxX; skip it when it isn't on
                // the interval so it doesn't collide with its neighbour.
                final onInterval = i % xInterval.toInt() == 0;
                if (i < 0 || i >= dates.length || value != i.toDouble() || !onInterval) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(AppFormatters.shortDate(dates[i]), style: axisStyle),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (bar, indexes) => [
            for (final _ in indexes)
              TouchedSpotIndicatorData(
                const FlLine(color: lineColor, strokeWidth: 1.5),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 5,
                    color: colors.surface,
                    strokeWidth: 2.5,
                    strokeColor: lineColor,
                  ),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.inverseSurface,
            tooltipBorderRadius: AppSpacing.borderRadiusMd,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${AppFormatters.shortDate(dates[s.x.toInt()])}\n',
                  theme.textTheme.labelSmall!.copyWith(color: colors.onInverseSurface),
                  children: [
                    TextSpan(
                      text: '${AppStrings.spentLabel}: ${AppFormatters.currency(s.y)}',
                      style: theme.textTheme.labelMedium!.copyWith(color: colors.onInverseSurface),
                    ),
                  ],
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lineColor.withValues(alpha: 0.28), lineColor.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
