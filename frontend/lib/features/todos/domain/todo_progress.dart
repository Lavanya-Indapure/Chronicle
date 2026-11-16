import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/domain/recurrence_rules.dart';

/// How much of one day's todo list got done.
class TodoDayStat {
  final int total;
  final int completed;

  const TodoDayStat({this.total = 0, this.completed = 0});

  /// 0.0–1.0; 0 when nothing was due.
  double get ratio => total == 0 ? 0 : completed / total;

  /// The day counts toward the streak (at least one todo ticked).
  bool get isActive => completed > 0;

  @override
  bool operator ==(Object other) => other is TodoDayStat && other.total == total && other.completed == completed;

  @override
  int get hashCode => Object.hash(total, completed);

  @override
  String toString() => 'TodoDayStat($completed/$total)';
}

/// Current and best run of consecutive active days.
class TodoStreaks {
  final int current;
  final int best;

  const TodoStreaks({this.current = 0, this.best = 0});
}

/// Pure progress maths for the dashboard (unit tested in
/// test/todo_progress_test.dart).
abstract final class TodoProgress {
  /// Per-day totals keyed by date (time stripped).
  ///
  /// A *pending* weekly/monthly todo isn't due on any particular day — it's
  /// due by the end of its week/month — so it's left out of that day's total.
  /// Once ticked it counts as done on the day it was ticked. This keeps an
  /// open weekly todo from dragging every day's percentage down.
  static Map<DateTime, TodoDayStat> dayStats(Iterable<TodoInstance> instances) {
    final totals = <DateTime, int>{};
    final done = <DateTime, int>{};
    for (final i in instances) {
      final type = i.recurrenceType ?? RecurrenceType.none;
      if (!i.isCompleted && RecurrenceRules.spansPeriod(type)) continue;
      final day = RecurrenceRules.dateOnly(i.scheduledDate);
      totals[day] = (totals[day] ?? 0) + 1;
      if (i.isCompleted) done[day] = (done[day] ?? 0) + 1;
    }
    return {
      for (final e in totals.entries) e.key: TodoDayStat(total: e.value, completed: done[e.key] ?? 0),
    };
  }

  /// Streaks over [stats], as of [today].
  ///
  /// The current streak counts back from today; if nothing is ticked yet
  /// today it counts back from yesterday instead, so the streak doesn't read
  /// 0 every morning before the first todo is done.
  static TodoStreaks streaks(Map<DateTime, TodoDayStat> stats, DateTime today) {
    bool active(DateTime d) => stats[d]?.isActive ?? false;

    var day = RecurrenceRules.dateOnly(today);
    if (!active(day)) day = _previousDay(day);
    var current = 0;
    while (active(day)) {
      current++;
      day = _previousDay(day);
    }

    final activeDays = stats.keys.where(active).toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in activeDays) {
      run = (prev != null && _previousDay(d) == prev) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return TodoStreaks(current: current, best: best);
  }

  // Calendar arithmetic (not Duration) so DST shifts can't skip or repeat a day.
  static DateTime _previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);
}
