import 'package:chronicle/features/health/domain/models/health_models.dart';

abstract class HydrationRemoteDatasource {
  Future<List<HydrationReminder>> getTodayLogs();
  Future<List<HydrationReminder>> getLogsBetweenDates(DateTime start, DateTime end);
  Future<void> logHydration(HydrationReminder log);
  Future<void> deleteLog(String id);
}
