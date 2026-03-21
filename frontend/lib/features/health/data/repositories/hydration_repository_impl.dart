import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/features/health/domain/repositories/hydration_repository.dart';
import 'package:chronicle/features/health/data/datasources/hydration_remote_datasource.dart';

class HydrationRepositoryImpl implements HydrationRepository {
  final HydrationRemoteDatasource _datasource;
  HydrationRepositoryImpl(this._datasource);

  @override
  Future<List<HydrationReminder>> getTodayLogs() => _datasource.getTodayLogs();

  @override
  Future<List<HydrationReminder>> getLogsBetweenDates(DateTime start, DateTime end) => _datasource.getLogsBetweenDates(start, end);

  @override
  Future<void> logHydration(HydrationReminder log) => _datasource.logHydration(log);

  @override
  Future<void> deleteLog(String id) => _datasource.deleteLog(id);
}
