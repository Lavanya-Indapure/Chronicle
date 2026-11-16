import 'package:chronicle/features/health/domain/models/health_models.dart';

/// Pure health calculations shared by the health screens and the dashboard.
abstract final class HealthStats {
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Today's water slots from [settings], merged with stored [logs] by clock
  /// time. Logs at times that aren't slots any more (settings changed) are
  /// kept so nothing the user logged disappears.
  static List<HydrationReminder> hydrationSlots(
    HealthSettings settings,
    List<HydrationReminder> logs,
    DateTime today,
  ) {
    final date = day(today);
    final byKey = {for (final l in logs) l.slotKey: l};
    final slots = <HydrationReminder>[
      for (final t in settings.hydrationSlotTimes)
        byKey.remove(_key(t.hour, t.minute)) ??
            HydrationReminder(
              id: '',
              logDate: date,
              logTime: DateTime(date.year, date.month, date.day, t.hour, t.minute),
              status: HydrationStatus.pending,
            ),
      ...byKey.values,
    ]..sort((a, b) => a.logTime.compareTo(b.logTime));
    return slots;
  }

  static String _key(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  /// Done glasses ÷ slots for the day (0 when there are no slots).
  static double hydrationFraction(List<HydrationReminder> slots) {
    if (slots.isEmpty) return 0;
    return slots.where((s) => s.status == HydrationStatus.done).length / slots.length;
  }

  /// Most recent finished sleep session.
  static SleepRecord? lastSleep(List<SleepRecord> records) {
    final done = records.where((r) => !r.isRecording).toList()
      ..sort((a, b) => b.endTime!.compareTo(a.endTime!));
    return done.firstOrNull;
  }

  /// Total sleep per wake-up day for the [days] days ending [today]
  /// (oldest first; days without sleep map to [Duration.zero]).
  static Map<DateTime, Duration> sleepByNight(List<SleepRecord> records, DateTime today, {int days = 7}) {
    final end = day(today);
    final result = {for (var i = days - 1; i >= 0; i--) end.subtract(Duration(days: i)): Duration.zero};
    for (final r in records) {
      final night = r.wakeDay;
      if (night != null && result.containsKey(night)) {
        result[night] = result[night]! + r.duration!;
      }
    }
    return result;
  }

  /// Average over nights that have any sleep logged in the window; null
  /// when none do.
  static Duration? averageSleep(List<SleepRecord> records, DateTime today, {int days = 7}) {
    final nights = sleepByNight(records, today, days: days).values.where((d) => d > Duration.zero).toList();
    if (nights.isEmpty) return null;
    final total = nights.fold<int>(0, (sum, d) => sum + d.inMinutes);
    return Duration(minutes: total ~/ nights.length);
  }

  /// Consecutive days up to today where [isDone] holds. Today not being done
  /// yet doesn't break the streak (the day isn't over).
  static int streak(List<ActivityLog> logs, DateTime today, bool Function(ActivityLog) isDone) {
    final doneDays = {for (final l in logs) if (isDone(l)) day(l.logDate)};
    var cursor = day(today);
    if (!doneDays.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var count = 0;
    while (doneDays.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }
}
