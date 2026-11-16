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
import 'package:chronicle/features/expenses/presentation/widgets/month_switcher.dart';

/// Spending more is flagged in warning orange, spending less in green.
const _moreColor = AppColors.warning;
const _lessColor = AppColors.success;
const _currentColor = AppColors.chartBlue;

/// "Compare" card: today vs yesterday, this week vs last week (both "so
/// far", like for like), or any two months picked by the user — with a
/// chart and the categories that moved most.
class ComparisonCard extends StatefulWidget {
  final List<Expense> expenses;
  final Color Function(String? categoryId) colorFor;

  /// Month the Month tab starts on (compared with the month before it).
  final DateTime initialMonth;

  /// Range the month pickers allow.
  final DateTime firstMonth;
  final DateTime lastMonth;

  /// Injected for tests; defaults to now.
  final DateTime? now;

  const ComparisonCard({
    super.key,
    required this.expenses,
    required this.colorFor,
    required this.initialMonth,
    required this.firstMonth,
    required this.lastMonth,
    this.now,
  });

  @override
  State<ComparisonCard> createState() => _ComparisonCardState();
}

class _ComparisonCardState extends State<ComparisonCard> {
  late ComparePeriod _period;
  late DateTime _month; // shown as "this"
  late DateTime _other; // compared against

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _resetMonths();
    // Day/week are about "now"; when looking at a past month start on Month.
    final current = DateTime(_now.year, _now.month);
    _period = _month == current ? ComparePeriod.week : ComparePeriod.month;
  }

  @override
  void didUpdateWidget(ComparisonCard old) {
    super.didUpdateWidget(old);
    // Follow the month switcher at the top of the screen.
    if (old.initialMonth != widget.initialMonth) _resetMonths();
  }

  void _resetMonths() {
    _month = DateTime(widget.initialMonth.year, widget.initialMonth.month);
    _other = DateTime(_month.year, _month.month - 1);
  }

  Future<void> _pick({required bool first}) async {
    final picked = await showMonthPicker(
      context,
      selected: first ? _month : _other,
      firstMonth: widget.firstMonth,
      lastMonth: widget.lastMonth,
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Picking the month already on the other side swaps them.
      if (first) {
        if (picked == _other) _other = _month;
        _month = picked;
      } else {
        if (picked == _month) _month = _other;
        _other = picked;
      }
    });
  }

  static String _label(ComparePeriod p) => switch (p) {
        ComparePeriod.day => AppStrings.compareDay,
        ComparePeriod.week => AppStrings.compareWeek,
        ComparePeriod.month => AppStrings.compareMonth,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _period == ComparePeriod.month
        ? ExpenseComparison.compareMonths(widget.expenses, _month, _other, _now)
        : ExpenseComparison.compare(widget.expenses, _period, _now);
    final hasChartData = [...c.currentSeries, ...c.previousSeries].any((v) => (v ?? 0) > 0);

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
          if (_period == ComparePeriod.month) ...[
            AppSpacing.gapMd,
            _MonthPair(
              month: _month,
              other: _other,
              onPickMonth: () => _pick(first: true),
              onPickOther: () => _pick(first: false),
            ),
          ],
          AppSpacing.gapMd,
          _Headline(comparison: c, now: _now),
          if (c.period != ComparePeriod.day && hasChartData) ...[
            AppSpacing.gapMd,
            SizedBox(
              height: AppSpacing.chartHeightCompact,
              child: c.period == ComparePeriod.week ? _WeekBars(comparison: c) : _MonthLines(comparison: c),
            ),
            AppSpacing.gapSm,
            _Legend(comparison: c),
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

/// "[Nov 2026 ▾]  vs  [Oct 2026 ▾]"
class _MonthPair extends StatelessWidget {
  final DateTime month;
  final DateTime other;
  final VoidCallback onPickMonth;
  final VoidCallback onPickOther;

  const _MonthPair({required this.month, required this.other, required this.onPickMonth, required this.onPickOther});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget button(DateTime m, Color dot, VoidCallback onTap, String semantics) => Expanded(
          child: Semantics(
            button: true,
            label: '$semantics: ${monthLabel(m)}',
            excludeSemantics: true,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: AppSpacing.accentDotSize,
                    height: AppSpacing.accentDotSize,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  AppSpacing.hGapXs,
                  Flexible(child: Text(monthLabel(m), overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
          ),
        );

    return Row(
      children: [
        button(month, _currentColor, onPickMonth, AppStrings.compareFirstMonth),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(AppStrings.vs, style: theme.textTheme.bodySmall),
        ),
        button(other, _mutedColor(context), onPickOther, AppStrings.compareSecondMonth),
      ],
    );
  }
}

/// "Nov 2026".
String monthLabel(DateTime m) => DateFormat('MMM yyyy').format(m);

Color _mutedColor(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

bool _isWholeMonth(DateTime start, DateTime end) =>
    start.day == 1 && DateTime(end.year, end.month, end.day + 1).month != end.month;

/// "Nov 2026" for a whole month, else "1–18 Nov".
String _rangeLabel(DateTime start, DateTime end) =>
    _isWholeMonth(start, end) ? monthLabel(start) : '${start.day}–${AppFormatters.dayMonth(end)}';

class _Headline extends StatelessWidget {
  final PeriodComparison comparison;
  final DateTime now;

  const _Headline({required this.comparison, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = comparison;
    final thisMonth = DateTime(now.year, now.month);
    final (String title, String versus) = switch (c.period) {
      ComparePeriod.day => (AppStrings.compareTodaySoFar, AppStrings.compareVsYesterday),
      ComparePeriod.week => (AppStrings.compareWeekSoFar, AppStrings.compareVsLastWeek),
      ComparePeriod.month => (
          c.currentStart == thisMonth ? AppStrings.compareMonthSoFar : _rangeLabel(c.currentStart, c.currentEnd),
          _rangeLabel(c.previousStart, c.previousEnd),
        ),
    };

    final change = c.change;
    final String detail;
    final Color? detailColor;
    if (change == null) {
      final nothing = switch (c.period) {
        ComparePeriod.day => AppStrings.compareNothingBefore, // "Nothing spent yesterday"
        ComparePeriod.week => AppStrings.compareNothingBy, // "… by this point last week"
        ComparePeriod.month => AppStrings.compareNothingIn, // "… in Oct 2026"
      };
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

  /// "Yesterday" / "9–11 Nov" / "Oct 2026" / "1–18 Oct".
  static String _previousLabel(PeriodComparison c) => switch (c.period) {
        ComparePeriod.day => AppStrings.yesterday,
        ComparePeriod.month => _rangeLabel(c.previousStart, c.previousEnd),
        ComparePeriod.week => c.previousStart == c.previousEnd
            ? AppFormatters.dayMonth(c.previousStart)
            : '${c.previousStart.day}–${AppFormatters.dayMonth(c.previousEnd)}',
      };
}

/// Series names: "This week / Last week" or the two months picked.
(String, String) _seriesNames(PeriodComparison c) => c.period == ComparePeriod.week
    ? (AppStrings.compareThisWeek, AppStrings.compareLastWeek)
    : (monthLabel(c.currentStart), monthLabel(c.previousStart));

class _Legend extends StatelessWidget {
  final PeriodComparison comparison;

  const _Legend({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = _mutedColor(context);
    final (now, before) = _seriesNames(comparison);

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
    final muted = _mutedColor(context);
    final maxY = [...c.previousSeries, ...c.currentSeries].whereType<double>().fold<double>(0, math.max);
    final days = [for (var i = 0; i < 7; i++) c.currentStart.add(Duration(days: i))];

    return Semantics(
      label: [
        for (var i = 0; i < 7; i++)
          '${DateFormat.E().format(days[i])}: ${AppFormatters.currency(c.currentSeries[i] ?? 0)} '
              '${AppStrings.vs} ${AppFormatters.currency(c.previousSeries[i] ?? 0)}',
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
                  BarChartRodData(toY: c.previousSeries[i] ?? 0, width: AppSpacing.sm, color: muted, borderRadius: AppSpacing.borderRadiusSm),
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

/// Running total through each month by day of month: the compared month
/// (muted, dashed) and the main one — shows which month spent faster.
class _MonthLines extends StatelessWidget {
  final PeriodComparison comparison;

  const _MonthLines({required this.comparison});

  static List<FlSpot> _spots(List<double?> series) => [
        for (var i = 0; i < series.length; i++)
          if (series[i] != null) FlSpot(i + 1.0, series[i]!),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final c = comparison;
    final muted = _mutedColor(context);
    final (currentName, previousName) = _seriesNames(c);
    final current = _spots(c.currentSeries);
    final previous = _spots(c.previousSeries);
    final maxX = math.max(c.currentSeries.length, c.previousSeries.length).toDouble();
    final maxY = [...c.previousSeries, ...c.currentSeries].whereType<double>().fold<double>(0, math.max);

    return Semantics(
      label: '$currentName: ${AppFormatters.currency(current.lastOrNull?.y ?? 0)}, '
          '$previousName: ${AppFormatters.currency(previous.lastOrNull?.y ?? 0)}',
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
                    '${s.barIndex == 0 ? previousName : currentName} · '
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
          // Arrow as an icon: Poppins has no "→" glyph.
          Text(AppFormatters.currency(change.previous), style: theme.textTheme.bodySmall),
          Icon(Icons.arrow_forward_rounded, size: AppSpacing.sm + AppSpacing.xs, color: theme.colorScheme.onSurfaceVariant),
          Text(AppFormatters.currency(change.current), style: theme.textTheme.bodySmall),
          AppSpacing.hGapSm,
          Text(
            '${more ? '+' : '-'}${AppFormatters.currency(change.delta.abs())}',
            style: theme.textTheme.labelMedium?.copyWith(color: more ? _moreColor : _lessColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
