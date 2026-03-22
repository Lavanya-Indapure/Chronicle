import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';

class ExpenseAnalyticsCard extends StatelessWidget {
  final ExpenseAnalytics analytics;
  
  const ExpenseAnalyticsCard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return ChronicleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Expenses", 
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                )
              ),
              if (analytics.warningMessage != null)
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            currencyFormat.format(analytics.totalSpent),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            "Total spent • Avg ${currencyFormat.format(analytics.averageDaily)} per day",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          
          if (analytics.warningMessage != null) ...[
            AppSpacing.gapMd,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.error, size: 16),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      analytics.warningMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (analytics.chartData.isNotEmpty) ...[
            AppSpacing.gapLg,
            SizedBox(
              height: 160,
              child: _ExpenseLineChart(chartData: analytics.chartData),
            ),
          ]
        ],
      ),
    );
  }
}

class _ExpenseLineChart extends StatelessWidget {
  final Map<String, double> chartData;

  const _ExpenseLineChart({required this.chartData});

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    
    // Convert to spots
    final sortedKeys = chartData.keys.toList()..sort();
    final spots = <FlSpot>[];
    double maxAmount = 0;
    
    for (int i = 0; i < sortedKeys.length; i++) {
      final amount = chartData[sortedKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), amount));
      if (amount > maxAmount) maxAmount = amount;
    }

    final interval = maxAmount > 0 ? (maxAmount / 4) : 100.0;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval > 0 ? interval : null,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (sortedKeys.length / 4).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  final dateStr = sortedKeys[value.toInt()];
                  final date = DateTime.parse(dateStr);
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      DateFormat('MMM d').format(date),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => theme.colorScheme.surface,
            tooltipBorder: BorderSide(color: theme.colorScheme.outlineVariant),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '₹${spot.y.toInt()}',
                  theme.textTheme.labelMedium!.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        minX: 0,
        maxX: (sortedKeys.length - 1).toDouble(),
        minY: 0,
        maxY: maxAmount * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: theme.colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: theme.colorScheme.primary,
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface,
              ),
              checkToShowDot: (spot, barData) => spot.x == (sortedKeys.length - 1),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.primary.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
