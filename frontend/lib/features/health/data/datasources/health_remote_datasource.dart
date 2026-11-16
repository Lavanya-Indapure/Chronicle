import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/core/utils/db_time.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';

/// All Supabase calls for the health module.
class HealthRemoteDatasource {
  final SupabaseClient _client;

  HealthRemoteDatasource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ── Settings ──

  Future<Map<String, dynamic>?> getSettings() {
    return _client.from('health_settings').select().eq('user_id', _userId).maybeSingle();
  }

  /// Select-then-write instead of upsert so this doesn't depend on a unique
  /// constraint on `user_id`.
  Future<void> saveSettings(HealthSettings settings) async {
    final data = settings.toJson(_userId)..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final existing = await getSettings();
    if (existing == null) {
      await _client.from('health_settings').insert(data);
    } else {
      await _client.from('health_settings').update(data).eq('user_id', _userId);
    }
  }

  // ── Hydration ──

  Future<List<Map<String, dynamic>>> getHydrationLogs(DateTime day) async {
    final rows = await _client
        .from('hydration_logs')
        .select()
        .eq('user_id', _userId)
        .eq('log_date', DbTime.date(day))
        .order('log_time');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> saveHydration(HydrationReminder log) async {
    final data = log.toJson(_userId);
    if (log.isStored) {
      return _client.from('hydration_logs').update(data).eq('id', log.id).select().single();
    }
    return _client
        .from('hydration_logs')
        .upsert(data, onConflict: 'user_id,log_date,log_time')
        .select()
        .single();
  }

  Future<void> deleteHydration(String id) async {
    await _client.from('hydration_logs').delete().eq('id', id);
  }

  // ── Sleep ──

  Future<List<Map<String, dynamic>>> getSleepSince(DateTime since) async {
    final rows = await _client
        .from('sleep_logs')
        .select()
        .eq('user_id', _userId)
        .gte('sleep_start', DbTime.encode(since))
        .order('sleep_start', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> getOpenSleep() async {
    final rows = await _client
        .from('sleep_logs')
        .select()
        .eq('user_id', _userId)
        .filter('sleep_end', 'is', null)
        .order('sleep_start', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>> startSleep(DateTime start) {
    return _client
        .from('sleep_logs')
        .insert({'user_id': _userId, 'sleep_start': DbTime.encode(start)})
        .select()
        .single();
  }

  Future<void> finishSleep(String id, DateTime start, DateTime end) {
    return _writeSleep(
      (data) => _client.from('sleep_logs').update(data).eq('id', id),
      {'sleep_end': DbTime.encode(end)},
      end.difference(start),
    );
  }

  Future<void> addSleep(DateTime start, DateTime end) {
    return _writeSleep(
      (data) => _client.from('sleep_logs').insert(data),
      {'user_id': _userId, 'sleep_start': DbTime.encode(start), 'sleep_end': DbTime.encode(end)},
      end.difference(start),
    );
  }

  /// Writes [data] plus `duration_minutes`; if the database computes that
  /// column itself (generated column, Postgres error 428C9) retries without it.
  Future<void> _writeSleep(
    Future<void> Function(Map<String, dynamic> data) write,
    Map<String, dynamic> data,
    Duration duration,
  ) async {
    try {
      await write({...data, 'duration_minutes': duration.inMinutes});
    } on PostgrestException catch (e) {
      if (e.code != '428C9') rethrow;
      await write(data);
    }
  }

  Future<void> deleteSleep(String id) async {
    await _client.from('sleep_logs').delete().eq('id', id);
  }

  // ── Activity ──

  Future<List<Map<String, dynamic>>> getActivitySince(DateTime since) async {
    final rows = await _client
        .from('activity_logs')
        .select()
        .eq('user_id', _userId)
        .gte('log_date', DbTime.date(since))
        .order('log_date', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// One row per day: updates the day's row when it exists, inserts otherwise.
  Future<Map<String, dynamic>> saveActivity(ActivityLog log) async {
    final data = {
      'user_id': _userId,
      'log_date': DbTime.date(log.logDate),
      'exercise_done': log.exerciseDone,
      'meditation_done': log.meditationDone,
      'notes': log.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    var id = log.id;
    if (id.isEmpty) {
      final existing = await _client
          .from('activity_logs')
          .select('id')
          .eq('user_id', _userId)
          .eq('log_date', data['log_date'] as String)
          .limit(1);
      if (existing.isNotEmpty) id = existing.first['id'] as String;
    }
    if (id.isEmpty) {
      return _client.from('activity_logs').insert(data).select().single();
    }
    return _client.from('activity_logs').update(data).eq('id', id).select().single();
  }
}
