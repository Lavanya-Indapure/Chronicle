import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';
import 'package:chronicle/features/todos/domain/todo_progress.dart';

/// Gap between heatmap cells.
const double _cellGap = 3;

/// Upper bound so cells stay small squares on wide screens.
const double _maxCell = 16;

/// Width of the weekday label column.
const double _labelWidth = 26;

/// Fill strength per intensity level (0 = nothing done).
const List<double> _levelAlpha = [0, 0.35, 0.55, 0.8, 1];

/// GitHub-style grid of daily todo completion: one column per week
/// (Monday on top), shaded by the share of that day's todos that got done.
class TodoHeatmapCard extends StatelessWidget {
  final Map<DateTime, TodoDayStat> dayStats;
  final DateTime today;

  const TodoHeatmapCard({super.key, required this.dayStats, required this.today});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: AppStrings.todoHeatmapTitle,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: '  ${TodoAnalytics.heatmapWeeks} ${AppStrings.todoHeatmapWeeksSuffix}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const _HeatmapLegend(),
            ],
          ),
          AppSpacing.gapSm,
          Semantics(
            label: AppStrings.todoHeatmapSemantics,
            container: true,
            child: _HeatmapGrid(dayStats: dayStats, today: today),
          ),
        ],
      ),
    );
  }
}

/// Shade level 0–4 for a day.
int _levelFor(TodoDayStat? stat) {
  if (stat == null || stat.completed == 0) return 0;
  final r = stat.ratio;
  if (r >= 1) return 4;
  if (r >= 0.66) return 3;
  if (r >= 0.33) return 2;
  return 1;
}

Color _emptyColor(ThemeData theme) => theme.colorScheme.surfaceContainerHighest;

Color _levelColor(ThemeData theme, int level) =>
    level == 0 ? _emptyColor(theme) : AppColors.success.withValues(alpha: _levelAlpha[level]);

class _HeatmapGrid extends StatelessWidget {
  final Map<DateTime, TodoDayStat> dayStats;
  final DateTime today;

  const _HeatmapGrid({required this.dayStats, required this.today});

  @override
  Widget build(BuildContext context) {
    const weeks = TodoAnalytics.heatmapWeeks;
    final start = TodoAnalytics.heatmapStart(today);
    final todayDate = DateTime(today.year, today.month, today.day);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - _labelWidth - _cellGap * (weeks - 1);
        final cell = (available / weeks).clamp(0.0, _maxCell);
        final columns = [
          for (var w = 0; w < weeks; w++)
            [for (var d = 0; d < DateTime.daysPerWeek; d++) DateTime(start.year, start.month, start.day + w * 7 + d)],
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthLabels(columns: columns, cell: cell),
            AppSpacing.gapXs,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WeekdayLabels(firstWeek: columns.first, cell: cell),
                for (var w = 0; w < weeks; w++) ...[
                  if (w > 0) const SizedBox(width: _cellGap),
                  Column(
                    children: [
                      for (var d = 0; d < DateTime.daysPerWeek; d++) ...[
                        if (d > 0) const SizedBox(height: _cellGap),
                        _HeatmapCell(
                          date: columns[w][d],
                          stat: dayStats[columns[w][d]],
                          size: cell,
                          isToday: columns[w][d] == todayDate,
                          isFuture: columns[w][d].isAfter(todayDate),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Month name above the first column of each month; skipped when it would
/// collide with the previous label.
class _MonthLabels extends StatelessWidget {
  final List<List<DateTime>> columns;
  final double cell;

  const _MonthLabels({required this.columns, required this.cell});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    final step = cell + _cellGap;
    final labels = <Widget>[];
    var lastLabelled = -3;
    for (var w = 0; w < columns.length; w++) {
      final monday = columns[w].first;
      final startsMonth = w == 0 || columns[w].any((d) => d.day == 1);
      if (!startsMonth || w - lastLabelled < 3) continue;
      // Label the month the column's Sunday is in (the newer month).
      final month = w == 0 ? monday : columns[w].last;
      labels.add(Positioned(
        left: _labelWidth + w * step,
        child: Text(AppFormatters.shortMonth(month), style: style, maxLines: 1),
      ));
      lastLabelled = w;
    }
    return SizedBox(
      height: (style?.fontSize ?? AppSpacing.md) * 1.4,
      width: double.infinity,
      child: Stack(clipBehavior: Clip.hardEdge, children: labels),
    );
  }
}

/// Mon / Wed / Fri labels, like GitHub.
class _WeekdayLabels extends StatelessWidget {
  final List<DateTime> firstWeek;
  final double cell;

  const _WeekdayLabels({required this.firstWeek, required this.cell});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      width: _labelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var d = 0; d < DateTime.daysPerWeek; d++) ...[
            if (d > 0) const SizedBox(height: _cellGap),
            SizedBox(
              height: cell,
              child: d.isEven && d < 6
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(DateFormat.E().format(firstWeek[d]), style: style),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final DateTime date;
  final TodoDayStat? stat;
  final double size;
  final bool isToday;
  final bool isFuture;

  const _HeatmapCell({
    required this.date,
    required this.stat,
    required this.size,
    required this.isToday,
    required this.isFuture,
  });

  String get _description {
    final day = AppFormatters.weekdayDayMonth(date);
    final s = stat;
    final detail = (s == null || s.total == 0)
        ? AppStrings.todoHeatmapNothingDue
        : '${s.completed}/${s.total} ${AppStrings.todoHeatmapDone}';
    return isToday ? '$day (${AppStrings.todoHeatmapToday}): $detail' : '$day: $detail';
  }

  @override
  Widget build(BuildContext context) {
    if (isFuture) return SizedBox.square(dimension: size);
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(size / 4);
    return Tooltip(
      message: _description,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _levelColor(theme, _levelFor(stat)),
          borderRadius: radius,
          border: isToday ? Border.all(color: theme.colorScheme.onSurface, width: 1.5) : null,
        ),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall;
    const swatch = AppSpacing.sm + 2;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.todoHeatmapLess, style: style),
          AppSpacing.hGapXs,
          for (var level = 0; level < _levelAlpha.length; level++) ...[
            if (level > 0) const SizedBox(width: 2),
            Container(
              width: swatch,
              height: swatch,
              decoration: BoxDecoration(
                color: _levelColor(theme, level),
                borderRadius: BorderRadius.circular(swatch / 4),
              ),
            ),
          ],
          AppSpacing.hGapXs,
          Text(AppStrings.todoHeatmapMore, style: style),
        ],
      ),
    );
  }
}
