import 'package:chronicle/core/errors/error_handler.dart';
import 'package:chronicle/core/services/logger_service.dart';
import 'package:chronicle/features/health/data/datasources/health_remote_datasource.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/features/health/domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  final HealthRemoteDatasource _datasource;

  HealthRepositoryImpl(this._datasource);

  /// Runs [action], logging and mapping failures to an `AppException`.
  Future<T> _guard<T>(String what, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, st) {
      LoggerService.error('Failed to $what', error: e, stackTrace: st, tag: 'Health');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<HealthSettings> getSettings() => _guard('load health settings', () async {
        final row = await _datasource.getSettings();
        return row == null ? const HealthSettings() : HealthSettings.fromJson(row);
      });

  @override
  Future<void> saveSettings(HealthSettings settings) =>
      _guard('save health settings', () => _datasource.saveSettings(settings));

  @override
  Future<List<HydrationReminder>> getHydrationLogs(DateTime day) => _guard('load hydration', () async {
        final rows = await _datasource.getHydrationLogs(day);
        return rows.map(HydrationReminder.fromJson).toList();
      });

  @override
  Future<HydrationReminder> saveHydration(HydrationReminder log) => _guard('log hydration', () async {
        return HydrationReminder.fromJson(await _datasource.saveHydration(log));
      });

  @override
  Future<void> deleteHydration(String id) => _guard('undo hydration', () => _datasource.deleteHydration(id));

  @override
  Future<List<SleepRecord>> getSleepSince(DateTime since) => _guard('load sleep', () async {
        final rows = await _datasource.getSleepSince(since);
        return rows.map(SleepRecord.fromJson).toList();
      });

  @override
  Future<SleepRecord?> getOpenSleep() => _guard('load sleep', () async {
        final row = await _datasource.getOpenSleep();
        return row == null ? null : SleepRecord.fromJson(row);
      });

  @override
  Future<SleepRecord> startSleep(DateTime start) => _guard('start sleep', () async {
        return SleepRecord.fromJson(await _datasource.startSleep(start));
      });

  @override
  Future<void> finishSleep(String id, DateTime start, DateTime end) =>
      _guard('finish sleep', () => _datasource.finishSleep(id, start, end));

  @override
  Future<void> addSleep(DateTime start, DateTime end) => _guard('add sleep', () => _datasource.addSleep(start, end));

  @override
  Future<void> deleteSleep(String id) => _guard('delete sleep', () => _datasource.deleteSleep(id));

  @override
  Future<List<ActivityLog>> getActivitySince(DateTime since) => _guard('load activity', () async {
        final rows = await _datasource.getActivitySince(since);
        return rows.map(ActivityLog.fromJson).toList();
      });

  @override
  Future<ActivityLog> saveActivity(ActivityLog log) => _guard('save activity', () async {
        return ActivityLog.fromJson(await _datasource.saveActivity(log));
      });
}
