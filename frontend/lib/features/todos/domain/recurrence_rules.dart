import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';

/// Pure recurrence rules for todo templates — no I/O, so they're unit tested
/// directly (test/todo_recurrence_rules_test.dart).
///
/// A recurring template is due once per *period*:
/// - daily   → the day itself
/// - weekly  → the ISO week (Monday–Sunday)
/// - monthly → the calendar month
///
/// Weekly and monthly todos keep ONE instance per period. While it's
/// pending it is moved forward to today, so it shows every day until
/// ticked; once ticked it stays on the day it was done and doesn't come back
/// until the next period. Moving (rather than creating a new copy each day)
/// keeps history to one row per period, so an unfinished weekly todo doesn't
/// leave a trail of unticked duplicates on every earlier day.
abstract final class RecurrenceRules {
  /// Strips the time part.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// First day of the period containing [day].
  static DateTime periodStart(RecurrenceType type, DateTime day) {
    final d = dateOnly(day);
    switch (type) {
      case RecurrenceType.weekly:
        return DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));
      case RecurrenceType.monthly:
        return DateTime(d.year, d.month);
      case RecurrenceType.daily:
      case RecurrenceType.none:
        return d;
    }
  }

  /// Earliest day any weekly/monthly period containing [today] starts on —
  /// the lower bound for a single query covering every template's period.
  static DateTime earliestPeriodStart(DateTime today) {
    final week = periodStart(RecurrenceType.weekly, today);
    final month = periodStart(RecurrenceType.monthly, today);
    return week.isBefore(month) ? week : month;
  }

  /// Whether this type keeps one instance per multi-day period.
  static bool spansPeriod(RecurrenceType type) =>
      type == RecurrenceType.weekly || type == RecurrenceType.monthly;

  /// Decides what to do for a template on [today], given its instances
  /// (any dates — ones outside the current period are ignored).
  ///
  /// One-time todos always get [TodayPlan.none]: their first instance is
  /// created with the template and carry-forward handles the rest.
  static TodayPlan planToday({
    required RecurrenceType type,
    required DateTime today,
    required Iterable<TodoInstance> instances,
  }) {
    final day = dateOnly(today);
    if (type == RecurrenceType.none) return const TodayPlan.none();

    final start = periodStart(type, day);
    final inPeriod = instances.where((i) {
      final d = dateOnly(i.scheduledDate);
      return !d.isBefore(start) && !d.isAfter(day);
    }).toList();

    // Already on today's list (ticked or not) → nothing to do.
    if (inPeriod.any((i) => dateOnly(i.scheduledDate) == day)) {
      return const TodayPlan.none();
    }
    if (type == RecurrenceType.daily) return const TodayPlan.create();

    // Done earlier this period → hidden until the next period.
    if (inPeriod.any((i) => i.isCompleted)) return const TodayPlan.none();

    // Still pending from an earlier day this period → bring the most recent
    // copy forward. (Older pending copies only exist from before this rule.)
    if (inPeriod.isNotEmpty) {
      inPeriod.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      return TodayPlan.move(inPeriod.last.id);
    }
    return const TodayPlan.create();
  }
}

enum TodayPlanKind { none, create, move }

/// Outcome of [RecurrenceRules.planToday].
class TodayPlan {
  final TodayPlanKind kind;

  /// Instance to reschedule to today; set only for [TodayPlanKind.move].
  final String? instanceId;

  const TodayPlan.none()
      : kind = TodayPlanKind.none,
        instanceId = null;
  const TodayPlan.create()
      : kind = TodayPlanKind.create,
        instanceId = null;
  const TodayPlan.move(String this.instanceId) : kind = TodayPlanKind.move;

  @override
  bool operator ==(Object other) => other is TodayPlan && other.kind == kind && other.instanceId == instanceId;

  @override
  int get hashCode => Object.hash(kind, instanceId);

  @override
  String toString() => 'TodayPlan.${kind.name}${instanceId == null ? '' : '($instanceId)'}';
}
