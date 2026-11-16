// Unit tests for weekly/monthly todo periods (RecurrenceRules) and the
// dashboard's per-day completion + streak maths (TodoProgress).

import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/domain/recurrence_rules.dart';
import 'package:chronicle/features/todos/domain/todo_progress.dart';

TodoInstance _inst(String id, DateTime day, {bool done = false, RecurrenceType? type}) => TodoInstance(
      id: id,
      templateId: 't',
      userId: 'u',
      title: 'x',
      scheduledDate: day,
      isCompleted: done,
      createdAt: day,
      updatedAt: day,
      recurrenceType: type,
    );

// 2026-11-16 is a Monday.
final _mon = DateTime(2026, 11, 16);
final _wed = DateTime(2026, 11, 18);
final _sun = DateTime(2026, 11, 22);
final _nextMon = DateTime(2026, 11, 23);

TodayPlan _plan(RecurrenceType type, DateTime today, List<TodoInstance> instances) =>
    RecurrenceRules.planToday(type: type, today: today, instances: instances);

void main() {
  group('periodStart', () {
    test('weekly starts on Monday', () {
      expect(RecurrenceRules.periodStart(RecurrenceType.weekly, _wed), _mon);
      expect(RecurrenceRules.periodStart(RecurrenceType.weekly, _sun), _mon);
      expect(RecurrenceRules.periodStart(RecurrenceType.weekly, _mon), _mon);
    });

    test('weekly crosses month and year boundaries', () {
      // Fri 1 Jan 2027 belongs to the week starting Mon 28 Dec 2026.
      expect(RecurrenceRules.periodStart(RecurrenceType.weekly, DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
    });

    test('monthly starts on the 1st; time of day is ignored', () {
      expect(RecurrenceRules.periodStart(RecurrenceType.monthly, DateTime(2026, 11, 30, 23, 59)), DateTime(2026, 11));
    });

    test('earliestPeriodStart covers both the week and the month', () {
      // Tue 3 Nov 2026: week started Mon 2 Nov, month started 1 Nov.
      expect(RecurrenceRules.earliestPeriodStart(DateTime(2026, 11, 3)), DateTime(2026, 11, 1));
      // Sun 1 Nov 2026: week started Mon 26 Oct.
      expect(RecurrenceRules.earliestPeriodStart(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
    });
  });

  group('planToday — weekly', () {
    test('first day of a fresh week creates an instance', () {
      expect(_plan(RecurrenceType.weekly, _mon, []), const TodayPlan.create());
    });

    test('already on today\'s list (ticked or not) → nothing', () {
      expect(_plan(RecurrenceType.weekly, _wed, [_inst('a', _wed)]), const TodayPlan.none());
      expect(_plan(RecurrenceType.weekly, _wed, [_inst('a', _wed, done: true)]), const TodayPlan.none());
    });

    test('pending from earlier this week → moved forward, not duplicated', () {
      expect(_plan(RecurrenceType.weekly, _wed, [_inst('a', _mon)]), const TodayPlan.move('a'));
    });

    test('moves the most recent pending copy', () {
      final plan = _plan(RecurrenceType.weekly, _wed, [_inst('old', _mon), _inst('new', DateTime(2026, 11, 17))]);
      expect(plan, const TodayPlan.move('new'));
    });

    test('completed earlier this week → hidden for the rest of the week', () {
      expect(_plan(RecurrenceType.weekly, _wed, [_inst('a', _mon, done: true)]), const TodayPlan.none());
      expect(_plan(RecurrenceType.weekly, _sun, [_inst('a', _mon, done: true)]), const TodayPlan.none());
    });

    test('completed last week → comes back next Monday as a new instance', () {
      expect(_plan(RecurrenceType.weekly, _nextMon, [_inst('a', _wed, done: true)]), const TodayPlan.create());
    });

    test('left pending last week → stays there; next week starts fresh', () {
      expect(_plan(RecurrenceType.weekly, _nextMon, [_inst('a', _sun)]), const TodayPlan.create());
    });
  });

  group('planToday — monthly', () {
    test('pending since the 3rd is moved to today', () {
      expect(
        _plan(RecurrenceType.monthly, DateTime(2026, 11, 20), [_inst('a', DateTime(2026, 11, 3))]),
        const TodayPlan.move('a'),
      );
    });

    test('done on the 3rd → hidden until next month', () {
      final done = [_inst('a', DateTime(2026, 11, 3), done: true)];
      expect(_plan(RecurrenceType.monthly, DateTime(2026, 11, 30), done), const TodayPlan.none());
      expect(_plan(RecurrenceType.monthly, DateTime(2026, 12, 1), done), const TodayPlan.create());
    });

    test('appears on any day of the month, not just the creation day', () {
      expect(_plan(RecurrenceType.monthly, DateTime(2026, 11, 27), []), const TodayPlan.create());
    });
  });

  group('planToday — daily and one-time unchanged', () {
    test('daily creates when missing today, even if done yesterday', () {
      expect(_plan(RecurrenceType.daily, _wed, [_inst('a', DateTime(2026, 11, 17), done: true)]), const TodayPlan.create());
      expect(_plan(RecurrenceType.daily, _wed, [_inst('a', _wed)]), const TodayPlan.none());
    });

    test('one-time never generates (carry-forward handles it)', () {
      expect(_plan(RecurrenceType.none, _wed, []), const TodayPlan.none());
      expect(_plan(RecurrenceType.none, _wed, [_inst('a', _mon)]), const TodayPlan.none());
    });
  });

  group('TodoProgress.dayStats', () {
    test('pending weekly/monthly todos are not counted against the day', () {
      final stats = TodoProgress.dayStats([
        _inst('d1', _wed, done: true, type: RecurrenceType.daily),
        _inst('d2', _wed, type: RecurrenceType.daily),
        _inst('w', _wed, type: RecurrenceType.weekly),
        _inst('m', _wed, type: RecurrenceType.monthly),
      ]);
      expect(stats[_wed], const TodoDayStat(total: 2, completed: 1));
    });

    test('a ticked weekly todo counts as done that day', () {
      final stats = TodoProgress.dayStats([
        _inst('d', _wed, type: RecurrenceType.daily),
        _inst('w', _wed, done: true, type: RecurrenceType.weekly),
      ]);
      expect(stats[_wed], const TodoDayStat(total: 2, completed: 1));
    });

    test('unknown recurrence (no template join) counts like one-time', () {
      final stats = TodoProgress.dayStats([_inst('x', DateTime(2026, 11, 18, 15), type: null)]);
      expect(stats[_wed], const TodoDayStat(total: 1, completed: 0));
    });
  });

  group('TodoProgress.streaks', () {
    Map<DateTime, TodoDayStat> active(List<DateTime> days) =>
        {for (final d in days) d: const TodoDayStat(total: 1, completed: 1)};

    test('counts back from today', () {
      final s = TodoProgress.streaks(active([_mon, DateTime(2026, 11, 17), _wed]), _wed);
      expect(s.current, 3);
      expect(s.best, 3);
    });

    test('nothing ticked yet today → counts from yesterday', () {
      final stats = active([_mon, DateTime(2026, 11, 17)])..[_wed] = const TodoDayStat(total: 2);
      expect(TodoProgress.streaks(stats, _wed).current, 2);
    });

    test('a gap breaks the current streak; best keeps the longest run', () {
      final s = TodoProgress.streaks(
        // Nothing on Tue 17 or Wed 18 → the run that ended Monday is over.
        active([DateTime(2026, 11, 1), DateTime(2026, 11, 2), DateTime(2026, 11, 3), _mon]),
        _wed,
      );
      expect(s.current, 0);
      expect(s.best, 3);
    });

    test('runs across a month boundary', () {
      final s = TodoProgress.streaks(active([DateTime(2026, 10, 31), DateTime(2026, 11, 1)]), DateTime(2026, 11, 1));
      expect(s.current, 2);
      expect(s.best, 2);
    });
  });
}
