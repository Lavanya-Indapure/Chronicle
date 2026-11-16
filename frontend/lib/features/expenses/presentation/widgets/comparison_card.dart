import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/expenses/domain/expense_comparison.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';

/// Spending more is flagged in warning orange, spending less in green.
const _moreColor = AppColors.warning;
const _lessColor = AppColors.success;
const _currentColor = AppColors.chartBlue;

/// "Compare" card: today / this week / this month so far vs the same stretch
/// of the previous period, with a chart and the categories that moved most.
class ComparisonCard extends StatefulWidget {
  final List<Expense> expenses;
  final Color Function(String? categoryId) colorFor;

  /// Injected for tests; defaults to now.
  final DateTime? now;

  const ComparisonCard({super.key, required this.expenses, required this.colorFor, this.now});

  @override
  State<ComparisonCard> createState() => _ComparisonCardState();
}

class _ComparisonCardState extends State<ComparisonCard> {
  ComparePeriod _period = ComparePeriod.week;

  static String _label(ComparePeriod p) => switch (p) {
        ComparePeriod.day => AppStrings.compareDay,
        ComparePeriod.week => AppStrings.compareWeek,
        ComparePeriod.month => AppStrings.compareMonth,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ExpenseComparison.compare(widget.expenses, _period, widget.now ?? DateTime.now());

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.compareTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          AppSpacing.gapSm,
          PillTabs<ComparePeriod>(
            values: ComparePeriod.values,
            labelOf: _label,
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          AppSpacing.gapMd,
          _Headline(comparison: c),
          if (c.period != ComparePeriod.day && (c.currentTotal > 0 || c.previousSeries.any((v) => v > 0))) ...[
            AppSpacing.gapMd,
            SizedBox(
              height: AppSpacing.chartHeightCompact,
              child: c.period == ComparePeriod.week ? _WeekBars(comparison: c) : _MonthLines(comparison: c),
            ),
            AppSpacing.gapSm,
            _Legend(period: c.period),
          ],
          if (c.changes.isNotEmpty) ...[
            AppSpacing.gapMd,
            Text(AppStrings.compareBiggestChanges, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            AppSpacing.gapSm,
            for (final change in c.changes) _ChangeRow(change: change, color: widget.colorFor(change.categoryId)),
          ],
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  final PeriodComparison comparison;

  const _Headline({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = comparison;
    final (String title, String versus) = switch (c.period) {
      ComparePeriod.day => (AppStrings.compareTodaySoFar, AppStrings.compareVsYesterday),
      ComparePeriod.week => (AppStrings.compareWeekSoFar, AppStrings.compareVsLastWeek),
      ComparePeriod.month => (AppStrings.compareMonthSoFar, AppStrings.compareVsLastMonth),
    };

    final change = c.change;
    final String detail;
    final Color? detailColor;
    if (change == null) {
      final nothing = c.period == ComparePeriod.day ? AppStrings.compareNothingBefore : AppStrings.compareNothingBy;
      detail = c.currentTotal > 0 ? '$nothing $versus' : AppStrings.compareNoSpending;
      detailColor = null;
    } else if ((change * 100).round() == 0) {
      detail = '${AppStrings.compareSameAs} $versus';
      detailColor = null;
    } else {
      final more = change > 0;
      detail = '${AppFormatters.currency(c.difference.abs())} (${(change.abs() * 100).round()}%) '
          '${more ? AppStrings.compareMoreThan : AppStrings.compareLessThan} $versus';
      detailColor = more ? _moreColor : _lessColor;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodySmall),
              Text(AppFormatters.currency(c.currentTotal), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              Row(
                children: [
                  if (detailColor != null) ...[
                    Icon(
                      change! > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: AppSpacing.md,
                      color: detailColor,
                    ),
                    AppSpacing.hGapXs,
                  ],
                  Expanded(child: Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: detailColor))),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.hGapMd,
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_previousLabel(c), style: theme.textTheme.bodySmall),
            Text(AppFormatters.currency(c.previousTotal), style: theme.textTheme.titleSmall),
          ],
        ),
      ],
    );
  }

  /// "Yesterday" / "10–13 Nov" / "1–16 Oct".
  static String _previousLabel(PeriodComparison c) {
    if (c.period == ComparePeriod.day) return AppStrings.yesterday;
    final start = AppFormatters.dayMonth(c.previousStart);
    return c.previousStart == c.previousEnd ? start : '${c.previousStart.day}–${AppFormatters.dayMonth(c.previousEnd)}';
  }
}

class _Legend extends StatelessWidget {
  final ComparePeriod period;

  const _Legend({required this.period});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
    final (String now, String before) = period == ComparePeriod.week
        ? (AppStrings.compareThisWeek, AppStrings.compareLastWeek)
        : (AppStrings.compareThisMonth, AppStrings.compareLastMonth);

    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.sm + AppSpacing.xs,
              height: AppSpacing.sm + AppSpacing.xs,
              decoration: BoxDecoration(color: color, borderRadius: AppSpacing.borderRadiusSm),
            ),
            AppSpacing.hGapXs,
            Text(label, style: theme.textTheme.labelSmall),
          ],
        );

    return Wrap(spacing: AppSpacing.md, children: [item(_currentColor, now), item(muted, before)]);
  }
}

/// Paired bars per weekday: last week (muted) and this week.
class _WeekBars extends StatelessWidget {
  final PeriodComparison comparison;

  const _WeekBars({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final c = comparison;
    final muted = colors.onSurfaceVariant.withValues(alpha: 0.45);
    final maxY = [...c.previousSeries, ...c.currentSeries.whereType<double>()].fold<double>(0, math.max);
    final days = [for (var i = 0; i < 7; i++) c.currentStart.add(Duration(days: i))];

    return Semantics(
      label: [
        for (var i = 0; i < 7; i++)
          '${DateFormat.E().format(days[i])}: ${AppFormatters.currency(c.currentSeries[i] ?? 0)} '
              '${AppStrings.vs} ${AppFormatters.currency(c.previousSeries[i])}',
      ].join(', '),
      excludeSemantics: true,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          minY: 0,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
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
                  if (i < 0 || i > 6) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(DateFormat.E().format(days[i]).substring(0, 2), style: theme.textTheme.labelSmall),
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
                '${rodIndex == 0 ? AppStrings.compareLastWeek : AppStrings.compareThisWeek}\n${AppFormatters.currency(rod.toY)}',
                theme.textTheme.labelSmall!.copyWith(color: colors.onInverseSurface),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < 7; i++)
              BarChartGroupData(
                x: i,
                barsSpace: AppSpacing.xs / 2,
                barRods: [
                  BarChartRodData(toY: c.previousSeries[i], width: AppSpacing.sm, color: muted, borderRadius: AppSpacing.borderRadiusSm),
                  BarChartRodData(
                    toY: c.currentSeries[i] ?? 0,
                    width: AppSpacing.sm,
                    color: c.currentSeries[i] == null ? Colors.transparent : _currentColor,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Running total through the month: last month (muted, dashed) and this
/// month up to today — shows whether you're ahead of last month's pace.
class _MonthLines extends StatelessWidget {
  final PeriodComparison comparison;

  const _MonthLines({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final c = comparison;
    final muted = colors.onSurfaceVariant.withValues(alpha: 0.45);
    final current = [
      for (var i = 0; i < c.currentSeries.length; i++)
        if (c.currentSeries[i] != null) FlSpot(i + 1.0, c.currentSeries[i]!),
    ];
    final previous = [for (var i = 0; i < c.previousSeries.length; i++) FlSpot(i + 1.0, c.previousSeries[i])];
    final maxX = math.max(c.currentSeries.length, c.previousSeries.length).toDouble();
    final maxY = [...c.previousSeries, ...c.currentSeries.whereType<double>()].fold<double>(0, math.max);

    return Semantics(
      label: '${AppStrings.compareThisMonth}: ${AppFormatters.currency(c.currentTotal)}, '
          '${AppStrings.compareLastMonth}: ${AppFormatters.currency(c.previousSeries.lastOrNull ?? 0)}',
      excludeSemantics: true,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: maxX,
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: AppSpacing.lg,
                interval: 7,
                getTitlesWidget: (value, meta) => value == meta.max && value % 7 != 1
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text('${value.toInt()}', style: theme.textTheme.labelSmall),
                      ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colors.inverseSurface,
              tooltipBorderRadius: AppSpacing.borderRadiusMd,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${s.barIndex == 0 ? AppStrings.compareLastMonth : AppStrings.compareThisMonth} · '
                    '${AppStrings.compareDayPrefix} ${s.x.toInt()}\n${AppFormatters.currency(s.y)}',
                    theme.textTheme.labelSmall!.copyWith(color: colors.onInverseSurface),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: previous,
              color: muted,
              barWidth: 2,
              dashArray: const [6, 4],
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: current,
              color: _currentColor,
              barWidth: 3,
              dotData: FlDotData(
                checkToShowDot: (spot, bar) => spot == bar.spots.last,
              ),
              belowBarData: BarAreaData(show: true, color: _currentColor.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "● Food   ₹1,200 → ₹2,400   +₹1,200"
class _ChangeRow extends StatelessWidget {
  final CategoryChange change;
  final Color color;

  const _ChangeRow({required this.change, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final more = change.delta > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: AppSpacing.accentDotSize,
            height: AppSpacing.accentDotSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(change.name ?? AppStrings.uncategorized, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
          ),
          Text(
            '${AppFormatters.currency(change.previous)} → ${AppFormatters.currency(change.current)}',
            style: theme.textTheme.bodySmall,
          ),
          AppSpacing.hGapSm,
          Text(
            '${more ? '+' : '−'}${AppFormatters.currency(change.delta.abs())}',
            style: theme.textTheme.labelMedium?.copyWith(color: more ? _moreColor : _lessColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
