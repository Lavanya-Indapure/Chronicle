import 'package:chronicle/features/expenses/domain/models/budget.dart';

/// How spending is tracking against a budget.
enum BudgetPace {
  /// Spent no faster than the period is passing.
  onTrack,

  /// Spending faster than the period is passing, but still under budget.
  ahead,

  /// Spent more than the budget.
  over,
}

/// A budget measured over one period (a week or a month).
class BudgetStatus {
  /// Ahead of pace = spent share exceeds elapsed share by more than this.
  static const paceTolerance = 0.1;

  final BudgetType type;
  final double budget;
  final double spent;
  final DateTime periodStart;
  final DateTime periodEnd; // inclusive

  /// Day the status is measured on; on/after [periodEnd] the period is over.
  final DateTime today;

  const BudgetStatus({
    required this.type,
    required this.budget,
    required this.spent,
    required this.periodStart,
    required this.periodEnd,
    required this.today,
  });

  DateTime get _today => DateTime(today.year, today.month, today.day);

  double get left => budget - spent;
  double get fraction => budget <= 0 ? 0 : spent / budget;
  bool get isOver => spent > budget;

  /// Past the last day of the period.
  bool get isFinished => _today.isAfter(periodEnd);

  int get totalDays => periodEnd.difference(periodStart).inDays + 1;

  /// Days remaining including today (0 once the period has ended).
  int get daysLeft => isFinished ? 0 : periodEnd.difference(_today).inDays + 1;

  /// What can still be spent per remaining day; null when over or finished.
  double? get perDayLeft => isOver || daysLeft == 0 ? null : left / daysLeft;

  /// Share of the period gone, counting today as used.
  double get elapsed => isFinished ? 1 : (_today.difference(periodStart).inDays + 1) / totalDays;

  BudgetPace get pace {
    if (isOver) return BudgetPace.over;
    if (!isFinished && fraction > elapsed + paceTolerance) return BudgetPace.ahead;
    return BudgetPace.onTrack;
  }
}

abstract final class Budgets {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The budget of [type] in force on [date]: the latest one that started on
  /// or before it. Null when none had been set yet.
  static Budget? effective(List<Budget> budgets, BudgetType type, DateTime date) {
    final day = _day(date);
    Budget? best;
    for (final b in budgets) {
      if (b.type != type || _day(b.startDate).isAfter(day)) continue;
      if (best == null ||
          b.startDate.isAfter(best.startDate) ||
          (b.startDate == best.startDate && b.createdAt.isAfter(best.createdAt))) {
        best = b;
      }
    }
    return best;
  }

  /// Monday→Sunday week containing [date].
  static (DateTime, DateTime) weekOf(DateTime date) {
    final monday = _day(date).subtract(Duration(days: date.weekday - 1));
    return (monday, monday.add(const Duration(days: 6)));
  }

  /// First→last day of [month].
  static (DateTime, DateTime) monthOf(DateTime month) =>
      (DateTime(month.year, month.month), DateTime(month.year, month.month + 1, 0));
}
