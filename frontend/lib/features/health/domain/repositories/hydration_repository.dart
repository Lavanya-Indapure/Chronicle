import 'package:chronicle/features/health/domain/models/health_models.dart';

abstract class HydrationRepository {
  Future<List<HydrationReminder>> getTodayLogs();
  Future<void> logHydration(HydrationReminder log);
  Future<void> deleteLog(String id);
}
