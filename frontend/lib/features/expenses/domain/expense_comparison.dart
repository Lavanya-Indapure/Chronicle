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
  /// Buckets after today are null.
  final List<double?> currentSeries;
  final List<double?> previousSeries;

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

  /// Today vs yesterday, this week vs last week, or this month vs last month.
  static PeriodComparison compare(List<Expense> expenses, ComparePeriod period, DateTime now) {
    final today = _day(now);
    switch (period) {
      case ComparePeriod.month:
        return compareMonths(expenses, DateTime(today.year, today.month), DateTime(today.year, today.month - 1), now);
      case ComparePeriod.day:
        final yesterday = today.subtract(const Duration(days: 1));
        return _build(expenses, period, today, today, yesterday, yesterday, const [], const []);
      case ComparePeriod.week:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final (cur, prev) = _weekSeries(expenses, monday, today);
        return _build(
          expenses,
          period,
          monday,
          today,
          monday.subtract(const Duration(days: 7)),
          today.subtract(const Duration(days: 7)),
          cur,
          prev,
        );
    }
  }

  /// Any two months: [month] (shown as "this") vs [other]. Whole months are
  /// compared, except when either is the current month — then both stop at
  /// today's day of month so a half-finished month isn't measured against a
  /// whole one. The chart still shows each month in full (up to today).
  static PeriodComparison compareMonths(List<Expense> expenses, DateTime month, DateTime other, DateTime now) {
    final today = _day(now);
    final thisMonth = DateTime(today.year, today.month);
    final a = DateTime(month.year, month.month);
    final b = DateTime(other.year, other.month);
    final cutoff = (a == thisMonth || b == thisMonth) ? today.day : null;

    DateTime end(DateTime first) {
      final days = _daysInMonth(first.year, first.month);
      return DateTime(first.year, first.month, cutoff == null || cutoff > days ? days : cutoff);
    }

    return _build(
      expenses,
      ComparePeriod.month,
      a,
      end(a),
      b,
      end(b),
      _runningSeries(expenses, a, today),
      _runningSeries(expenses, b, today),
    );
  }

  static PeriodComparison _build(
    List<Expense> expenses,
    ComparePeriod period,
    DateTime curStart,
    DateTime curEnd,
    DateTime prevStart,
    DateTime prevEnd,
    List<double?> curSeries,
    List<double?> prevSeries,
  ) {
    bool within(Expense e, DateTime start, DateTime end) {
      final d = _day(e.expenseDate);
      return !d.isBefore(start) && !d.isAfter(end);
    }

    final current = expenses.where((e) => within(e, curStart, curEnd)).toList();
    final previous = expenses.where((e) => within(e, prevStart, prevEnd)).toList();
    return PeriodComparison(
      period: period,
      currentStart: curStart,
      currentEnd: curEnd,
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
  static (List<double?>, List<double?>) _weekSeries(List<Expense> expenses, DateTime monday, DateTime today) {
    final lastMonday = monday.subtract(const Duration(days: 7));
    double dayTotal(DateTime day) => _sum(expenses.where((e) => _day(e.expenseDate) == day));
    return (
      [for (var i = 0; i < 7; i++) monday.add(Duration(days: i)).isAfter(today) ? null : dayTotal(monday.add(Duration(days: i)))],
      [for (var i = 0; i < 7; i++) dayTotal(lastMonday.add(Duration(days: i)))],
    );
  }

  /// Running total by day of [month]; days after [today] are null.
  static List<double?> _runningSeries(List<Expense> expenses, DateTime month, DateTime today) {
    final perDay = List<double>.filled(_daysInMonth(month.year, month.month), 0);
    for (final e in expenses) {
      final d = e.expenseDate;
      if (d.year == month.year && d.month == month.month) perDay[d.day - 1] += e.amount;
    }
    for (var i = 1; i < perDay.length; i++) {
      perDay[i] += perDay[i - 1];
    }
    return [
      for (var i = 0; i < perDay.length; i++)
        DateTime(month.year, month.month, i + 1).isAfter(today) ? null : perDay[i],
    ];
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
