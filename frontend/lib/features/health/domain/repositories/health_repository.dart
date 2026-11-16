import 'package:chronicle/features/health/domain/models/health_models.dart';

abstract class HealthRepository {
  // Settings
  Future<HealthSettings> getSettings();
  Future<void> saveSettings(HealthSettings settings);

  // Hydration
  Future<List<HydrationReminder>> getHydrationLogs(DateTime day);
  Future<HydrationReminder> saveHydration(HydrationReminder log);
  Future<void> deleteHydration(String id);

  // Sleep
  Future<List<SleepRecord>> getSleepSince(DateTime since);
  Future<SleepRecord?> getOpenSleep();
  Future<SleepRecord> startSleep(DateTime start);
  Future<void> finishSleep(String id, DateTime start, DateTime end);
  Future<void> addSleep(DateTime start, DateTime end);
  Future<void> deleteSleep(String id);

  // Activity
  Future<List<ActivityLog>> getActivitySince(DateTime since);
  Future<ActivityLog> saveActivity(ActivityLog log);
}
