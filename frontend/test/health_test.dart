// Health module: pure calculations (slots, sleep stats, streaks, dues
// reminder text) and smoke/interaction tests for the health screens with an
// in-memory repository, in both themes at phone width.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/db_time.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/health/domain/health_stats.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/features/health/domain/repositories/health_repository.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/health/presentation/screens/activity_screen.dart';
import 'package:chronicle/features/health/presentation/screens/health_home_screen.dart';
import 'package:chronicle/features/health/presentation/screens/health_settings_screen.dart';
import 'package:chronicle/features/health/presentation/screens/hydration_screen.dart';
import 'package:chronicle/features/health/presentation/screens/sleep_screen.dart';
import 'package:chronicle/features/reminders/presentation/controllers/reminder_sync_controller.dart';
import 'helpers/ui_test_harness.dart';

DateTime get _today => HealthStats.day(DateTime.now());

SleepRecord _night(int daysAgo, {int hours = 7, String? id}) {
  final wake = _today.subtract(Duration(days: daysAgo)).add(const Duration(hours: 7));
  return SleepRecord(id: id ?? 's$daysAgo', startTime: wake.subtract(Duration(hours: hours)), endTime: wake);
}

ActivityLog _activity(int daysAgo, {bool exercise = false, bool meditation = false}) => ActivityLog(
      id: 'a$daysAgo',
      logDate: _today.subtract(Duration(days: daysAgo)),
      exerciseDone: exercise,
      meditationDone: meditation,
    );

/// In-memory [HealthRepository].
class _FakeHealthRepository implements HealthRepository {
  HealthSettings settings = const HealthSettings();
  List<HydrationReminder> hydration = [];
  List<SleepRecord> sleep = [];
  List<ActivityLog> activity = [];
  int _id = 0;

  @override
  Future<HealthSettings> getSettings() async => settings;
  @override
  Future<void> saveSettings(HealthSettings s) async => settings = s;

  @override
  Future<List<HydrationReminder>> getHydrationLogs(DateTime day) async => hydration;
  @override
  Future<HydrationReminder> saveHydration(HydrationReminder log) async {
    final saved = log.withStatus(log.status, id: log.isStored ? log.id : 'h${_id++}');
    hydration = [...hydration.where((h) => h.slotKey != log.slotKey), saved];
    return saved;
  }

  @override
  Future<void> deleteHydration(String id) async => hydration = hydration.where((h) => h.id != id).toList();

  @override
  Future<List<SleepRecord>> getSleepSince(DateTime since) async => sleep;
  @override
  Future<SleepRecord?> getOpenSleep() async => sleep.where((s) => s.isRecording).firstOrNull;
  @override
  Future<SleepRecord> startSleep(DateTime start) async {
    final r = SleepRecord(id: 'open${_id++}', startTime: start);
    sleep = [r, ...sleep];
    return r;
  }

  @override
  Future<void> finishSleep(String id, DateTime start, DateTime end) async =>
      sleep = [for (final s in sleep) s.id == id ? SleepRecord(id: id, startTime: start, endTime: end) : s];
  @override
  Future<void> addSleep(DateTime start, DateTime end) async =>
      sleep = [SleepRecord(id: 'm${_id++}', startTime: start, endTime: end), ...sleep];
  @override
  Future<void> deleteSleep(String id) async => sleep = sleep.where((s) => s.id != id).toList();

  @override
  Future<List<ActivityLog>> getActivitySince(DateTime since) async => activity;
  @override
  Future<ActivityLog> saveActivity(ActivityLog log) async {
    final saved = log.copyWith(id: log.isStored ? log.id : 'a${_id++}');
    activity = [saved, ...activity.where((a) => HealthStats.day(a.logDate) != HealthStats.day(log.logDate))];
    return saved;
  }
}

void main() {
  final themes = setUpUiTests();

  group('DbTime', () {
    test('keeps the wall-clock time whatever offset the database adds', () {
      expect(DbTime.decode('2026-11-16T07:30:00+00:00'), DateTime(2026, 11, 16, 7, 30));
      expect(DbTime.decode('2026-11-16T07:30:00Z'), DateTime(2026, 11, 16, 7, 30));
      expect(DbTime.decode('2026-11-16 23:05:09'), DateTime(2026, 11, 16, 23, 5, 9));
      final local = DateTime(2026, 1, 2, 3, 4, 5);
      expect(DbTime.decode(DbTime.encode(local)), local);
    });

    test('parses time columns with or without seconds', () {
      const fallback = TimeOfDay(hour: 1, minute: 1);
      expect(DbTime.parseTime('07:30:00', fallback), const TimeOfDay(hour: 7, minute: 30));
      expect(DbTime.parseTime('7:05', fallback), const TimeOfDay(hour: 7, minute: 5));
      expect(DbTime.parseTime('nonsense', fallback), fallback);
      expect(DbTime.parseTime('25:00', fallback), fallback);
    });
  });

  group('Hydration slots', () {
    test('default schedule is every 30 min from 06:00 to 23:30', () {
      final times = const HealthSettings().hydrationSlotTimes;
      expect(times.length, 36);
      expect(times.first, const TimeOfDay(hour: 6, minute: 0));
      expect(times.last, const TimeOfDay(hour: 23, minute: 30));
    });

    test('settings read from the database drive the schedule', () {
      final s = HealthSettings.fromJson({
        'hydration_start_time': '08:00:00',
        'hydration_end_time': '20:00:00',
        'hydration_interval_minutes': 120,
      });
      expect(s.hydrationSlotTimes.map((t) => t.hour), [8, 10, 12, 14, 16, 18, 20]);
      expect(s.copyWith(hydrationEnd: const TimeOfDay(hour: 7, minute: 0)).hydrationSlotTimes, isEmpty);
    });

    test('stored logs fill their slot; off-schedule logs are kept', () {
      final s = HealthSettings.fromJson({'hydration_start_time': '08:00', 'hydration_end_time': '10:00', 'hydration_interval_minutes': 60});
      HydrationReminder log(int h, int m, HydrationStatus status) => HydrationReminder(
            id: 'x$h$m',
            logDate: _today,
            logTime: _today.add(Duration(hours: h, minutes: m)),
            status: status,
          );
      final slots = HealthStats.hydrationSlots(s, [log(9, 0, HydrationStatus.done), log(9, 30, HydrationStatus.skipped)], _today);
      expect(slots.map((x) => x.slotKey), ['08:00', '09:00', '09:30', '10:00']);
      expect(slots[1].status, HydrationStatus.done);
      expect(slots[0].isStored, isFalse);
      expect(HealthStats.hydrationFraction(slots), 0.25);
    });
  });

  group('Sleep stats', () {
    test('last night, nightly totals and 7-day average', () {
      final records = [_night(0, hours: 6), _night(1, hours: 8), _night(3, hours: 7), _night(10, hours: 3)];
      expect(HealthStats.lastSleep(records)!.duration, const Duration(hours: 6));
      final nights = HealthStats.sleepByNight(records, DateTime.now());
      expect(nights.length, 7);
      expect(nights.keys.last, _today);
      expect(nights[_today.subtract(const Duration(days: 2))], Duration.zero);
      // Nights without sleep don't drag the average down; day 10 is outside.
      expect(HealthStats.averageSleep(records, DateTime.now()), const Duration(hours: 7));
      expect(HealthStats.averageSleep([], DateTime.now()), isNull);
    });

    test('a session still in progress is ignored', () {
      final open = SleepRecord(id: 'o', startTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(HealthStats.lastSleep([open]), isNull);
      expect(HealthStats.averageSleep([open], DateTime.now()), isNull);
    });
  });

  group('Activity streaks', () {
    test('today not done yet does not break the streak; a gap does', () {
      final logs = [_activity(1, exercise: true), _activity(2, exercise: true), _activity(4, exercise: true)];
      expect(HealthStats.streak(logs, DateTime.now(), (l) => l.exerciseDone), 2);
      expect(HealthStats.streak([_activity(0, exercise: true), ...logs], DateTime.now(), (l) => l.exerciseDone), 3);
      expect(HealthStats.streak(logs, DateTime.now(), (l) => l.meditationDone), 0);
    });
  });

  group('Dues reminder text', () {
    Transaction tx(String id, double amount, TransactionType type, TransactionStatus status) => Transaction(
          id: id,
          userId: 'u',
          personName: 'Sam',
          amount: amount,
          type: type,
          status: status,
          date: _today,
          createdAt: _today,
        );

    test('summarises pending dues only', () {
      expect(ReminderSync.duesMessage([tx('1', 500, TransactionType.LEND, TransactionStatus.settled)]), isNull);
      final message = ReminderSync.duesMessage([
        tx('1', 500, TransactionType.LEND, TransactionStatus.pending),
        tx('2', 200, TransactionType.LEND, TransactionStatus.pending),
        tx('3', 300, TransactionType.BORROW, TransactionStatus.pending),
        tx('4', 999, TransactionType.BORROW, TransactionStatus.settled),
      ])!;
      expect(message, startsWith('3 ${AppStrings.reminderDuesPending}'));
      expect(message, contains('700'));
      expect(message, contains(AppStrings.reminderDuesToCollect));
      expect(message, contains('300'));
      expect(message, contains(AppStrings.reminderDuesToPay));
    });
  });

  group('Health screens', () {
    late _FakeHealthRepository repo;

    setUp(() {
      repo = _FakeHealthRepository()
        ..settings = const HealthSettings(sleepGoalHours: 8)
        ..sleep = [_night(0, hours: 6), _night(1, hours: 8), _night(2, hours: 5)]
        ..activity = [_activity(1, exercise: true, meditation: true), _activity(2, exercise: true)];
    });

    Future<void> pump(WidgetTester tester, Widget screen, ThemeData theme) => pumpAppScreen(
          tester,
          screen: screen,
          theme: theme,
          navIndex: NavTab.health,
          overrides: [healthRepositoryProvider.overrideWithValue(repo)],
        );

    for (final MapEntry(key: themeName, value: theme) in themes.all.entries) {
      testWidgets('home, water, sleep, activity and settings render ($themeName)', (tester) async {
        for (final screen in const [
          HealthHomeScreen(),
          HydrationScreen(),
          SleepScreen(),
          ActivityScreen(),
          HealthSettingsScreen(),
        ]) {
          await pump(tester, screen, theme);
          expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
        }
      });
    }

    testWidgets('home shows real numbers, not placeholders', (tester) async {
      await pump(tester, const HealthHomeScreen(), themes.light);
      expect(find.text('${AppStrings.sleepLastNight}: 6h 0m'), findsOneWidget);
      expect(find.text('1/2 ${AppStrings.activityDoneTodaySuffix}'), findsNothing); // nothing done today yet
      expect(find.text('0/2 ${AppStrings.activityDoneTodaySuffix}'), findsOneWidget);
      expect(find.textContaining('7h 30m'), findsNothing); // old hard-coded value
    });

    testWidgets('tapping a water slot logs it, tapping again undoes it', (tester) async {
      String glasses(int n) => '$n ${AppStrings.doneOf} 36 ${AppStrings.hydrationGlasses}';
      await pump(tester, const HydrationScreen(), themes.light);
      expect(find.text(glasses(0)), findsOneWidget);
      final firstSlot = find.text('6:00 AM');

      // Acts on the first slot, then scrolls back up so the hero is built.
      Future<void> onSlot(Future<void> Function(Finder) gesture) async {
        await tester.ensureVisible(firstSlot);
        await gesture(firstSlot);
        await tester.pump();
        tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
        await tester.pump();
      }

      await onSlot(tester.tap);
      expect(find.text(glasses(1)), findsOneWidget);
      expect(repo.hydration.single.status, HydrationStatus.done);
      await onSlot(tester.tap);
      expect(find.text(glasses(0)), findsOneWidget);
      expect(repo.hydration, isEmpty);
      // Long-press skips a slot without counting it as a glass.
      await onSlot(tester.longPress);
      expect(repo.hydration.single.status, HydrationStatus.skipped);
      expect(find.text(glasses(0)), findsOneWidget);
    });

    testWidgets('start sleep, then wake up, saves a real session', (tester) async {
      repo.sleep = [];
      await pump(tester, const SleepScreen(), themes.light);
      await tester.tap(find.text(AppStrings.sleepStart));
      await tester.pump();
      expect(find.text(AppStrings.sleepWakeUp), findsOneWidget);
      expect(repo.sleep.single.isRecording, isTrue);
      await tester.tap(find.text(AppStrings.sleepWakeUp));
      await tester.pump();
      expect(repo.sleep.single.isRecording, isFalse);
      expect(find.text(AppStrings.sleepStart), findsOneWidget);
    });

    testWidgets('toggling exercise saves today and bumps the streak', (tester) async {
      await pump(tester, const ActivityScreen(), themes.light);
      expect(find.text('2 ${AppStrings.activityDaysStreak}'), findsOneWidget);
      await tester.tap(find.text(AppStrings.activityExercise).first);
      await tester.pump();
      expect(repo.activity.first.exerciseDone, isTrue);
      expect(find.text('3 ${AppStrings.activityDaysStreak}'), findsOneWidget);
    });

    testWidgets('changing the interval saves settings and reshapes the slots', (tester) async {
      await pump(tester, const HealthSettingsScreen(), themes.light);
      expect(find.text('36 ${AppStrings.healthGlassesPerDay}'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '1${AppStrings.sleepHoursShort}'));
      await tester.pump();
      expect(repo.settings.hydrationIntervalMinutes, 60);
      expect(find.text('18 ${AppStrings.healthGlassesPerDay}'), findsOneWidget);
    });
  });
}
