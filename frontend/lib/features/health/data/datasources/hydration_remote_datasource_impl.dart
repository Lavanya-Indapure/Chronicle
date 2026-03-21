import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/features/health/data/datasources/hydration_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class HydrationRemoteDatasourceImpl implements HydrationRemoteDatasource {
  final SupabaseClient _client;
  HydrationRemoteDatasourceImpl(this._client);

  @override
  Future<List<HydrationReminder>> getTodayLogs() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _client
          .from('hydration_logs')
          .select()
          .eq('log_date', today);
      
      return (response as List).map((json) => HydrationReminder.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch hydration logs: $e');
    }
  }

  @override
  Future<void> logHydration(HydrationReminder log) async {
    try {
      final data = log.toJson();
      data['user_id'] = _client.auth.currentUser!.id;
      
      await _client.from('hydration_logs').upsert(
        data,
        onConflict: 'user_id,log_date,log_time',
      );
    } catch (e) {
      throw AppException('Failed to log hydration: $e');
    }
  }

  @override
  Future<void> deleteLog(String id) async {
    try {
      await _client.from('hydration_logs').delete().eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete log: $e');
    }
  }
}
