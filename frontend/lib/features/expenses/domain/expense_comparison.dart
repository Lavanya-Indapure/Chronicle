import 'package:chronicle/features/expenses/domain/models/expense.dart';

/// What the comparison card compares.
enum ComparePeriod { day, week, month }

/// One category's spending in both periods.
class CategoryChange {
  final String? categoryId;
  final String? name;
  final double current;
  final double previous;

  const CategoryChange({this.categoryId, this.name, required this.current, required this.previous});

  double get delta => current - previous;
}

/// Spending in the current period so far vs the same stretch of the
/// previous one ("like for like"): this week Mon→today vs last week
/// Mon→same weekday; this month 1st→today vs last month 1st→same day.
class PeriodComparison {
  final ComparePeriod period;

  /// Inclusive day ranges actually compared.
  final DateTime currentStart;
  final DateTime currentEnd;
  final DateTime previousStart;
  final DateTime previousEnd;

  final double currentTotal;
  final double previousTotal;

  /// Biggest category movers, largest absolute change first.
  final List<CategoryChange> changes;

  /// Chart series, one value per bucket (weekday for [ComparePeriod.week],
  /// day of month for [ComparePeriod.month]; empty for days).
  /// Week values are per-day totals; month values are running totals.
  /// Current-period buckets after today are null.
  final List<double?> currentSeries;
  final List<double> previousSeries;

  const PeriodComparison({
    required this.period,
    required this.currentStart,
    required this.currentEnd,
    required this.previousStart,
    required this.previousEnd,
    required this.currentTotal,
    required this.previousTotal,
    required this.changes,
    this.currentSeries = const [],
    this.previousSeries = const [],
  });

  /// Relative change (0.12 = 12% more); null when the previous period had
  /// no spending, since a percentage would be meaningless.
  double? get change => previousTotal > 0 ? (currentTotal - previousTotal) / previousTotal : null;

  double get difference => currentTotal - previousTotal;
}

abstract final class ExpenseComparison {
  /// How many category movers to report.
  static const maxChanges = 3;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  static PeriodComparison compare(List<Expense> expenses, ComparePeriod period, DateTime now) {
    final today = _day(now);
    final (DateTime curStart, DateTime prevStart, DateTime prevEnd) = switch (period) {
      ComparePeriod.day => (today, today.subtract(const Duration(days: 1)), today.subtract(const Duration(days: 1))),
      ComparePeriod.week => () {
          final monday = today.subtract(Duration(days: today.weekday - 1));
          return (monday, monday.subtract(const Duration(days: 7)), today.subtract(const Duration(days: 7)));
        }(),
      ComparePeriod.month => () {
          final prevMonthDays = _daysInMonth(today.year, today.month - 1);
          final prevFirst = DateTime(today.year, today.month - 1);
          final sameDay = today.day > prevMonthDays ? prevMonthDays : today.day;
          return (DateTime(today.year, today.month), prevFirst, DateTime(prevFirst.year, prevFirst.month, sameDay));
        }(),
    };

    bool within(Expense e, DateTime start, DateTime end) {
      final d = _day(e.expenseDate);
      return !d.isBefore(start) && !d.isAfter(end);
    }

    final current = expenses.where((e) => within(e, curStart, today)).toList();
    final previous = expenses.where((e) => within(e, prevStart, prevEnd)).toList();

    final (curSeries, prevSeries) = switch (period) {
      ComparePeriod.day => (const <double?>[], const <double>[]),
      ComparePeriod.week => _weekSeries(expenses, curStart, today),
      ComparePeriod.month => _monthSeries(expenses, today),
    };

    return PeriodComparison(
      period: period,
      currentStart: curStart,
      currentEnd: today,
      previousStart: prevStart,
      previousEnd: prevEnd,
      currentTotal: _sum(current),
      previousTotal: _sum(previous),
      changes: _changes(current, previous),
      currentSeries: curSeries,
      previousSeries: prevSeries,
    );
  }

  static double _sum(Iterable<Expense> list) => list.fold(0.0, (s, e) => s + e.amount);

  /// Per-weekday totals: this week (null after today) and all of last week.
  static (List<double?>, List<double>) _weekSeries(List<Expense> expenses, DateTime monday, DateTime today) {
    final lastMonday = monday.subtract(const Duration(days: 7));
    double dayTotal(DateTime day) => _sum(expenses.where((e) => _day(e.expenseDate) == day));
    return (
      [for (var i = 0; i < 7; i++) monday.add(Duration(days: i)).isAfter(today) ? null : dayTotal(monday.add(Duration(days: i)))],
      [for (var i = 0; i < 7; i++) dayTotal(lastMonday.add(Duration(days: i)))],
    );
  }

  /// Running totals by day of month: this month up to today, all of last month.
  static (List<double?>, List<double>) _monthSeries(List<Expense> expenses, DateTime today) {
    List<double> running(int year, int month) {
      final first = DateTime(year, month); // normalises month 0 → December
      final perDay = List<double>.filled(_daysInMonth(first.year, first.month), 0);
      for (final e in expenses) {
        final d = e.expenseDate;
        if (d.year == first.year && d.month == first.month) perDay[d.day - 1] += e.amount;
      }
      final days = perDay.length;
      for (var i = 1; i < days; i++) {
        perDay[i] += perDay[i - 1];
      }
      return perDay;
    }

    final thisMonth = running(today.year, today.month);
    return (
      [for (var i = 0; i < thisMonth.length; i++) i < today.day ? thisMonth[i] : null],
      running(today.year, today.month - 1),
    );
  }

  static List<CategoryChange> _changes(List<Expense> current, List<Expense> previous) {
    final byCategory = <String?, ({String? name, double current, double previous})>{};
    void add(Expense e, {required bool isCurrent}) {
      final old = byCategory[e.categoryId] ?? (name: e.category?.name, current: 0.0, previous: 0.0);
      byCategory[e.categoryId] = (
        name: old.name ?? e.category?.name,
        current: old.current + (isCurrent ? e.amount : 0),
        previous: old.previous + (isCurrent ? 0 : e.amount),
      );
    }

    for (final e in current) {
      add(e, isCurrent: true);
    }
    for (final e in previous) {
      add(e, isCurrent: false);
    }

    final changes = [
      for (final MapEntry(key: id, value: v) in byCategory.entries)
        if (v.current != v.previous) CategoryChange(categoryId: id, name: v.name, current: v.current, previous: v.previous),
    ]..sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    return changes.take(maxChanges).toList();
  }
}
