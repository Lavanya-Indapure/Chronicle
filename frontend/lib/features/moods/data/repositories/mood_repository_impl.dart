import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/moods/domain/models/mood_entry.dart';
import 'package:chronicle/features/moods/domain/repositories/mood_repository.dart';
import 'package:chronicle/features/moods/data/datasources/mood_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class MoodRemoteDatasourceImpl implements MoodRemoteDatasource {
  final SupabaseClient _client;
  MoodRemoteDatasourceImpl(this._client);

  @override
  Future<List<MoodEntry>> getMoods() async {
    try {
      final response = await _client.from('moods').select().order('log_date', ascending: false);
      return (response as List).map((json) => MoodEntry.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch moods: $e');
    }
  }

  @override
  Future<void> upsertMood(MoodEntry mood) async {
    try {
      final data = mood.toJson();
      data['user_id'] = _client.auth.currentUser!.id;
      await _client.from('moods').upsert(data, onConflict: 'user_id,log_date');
    } catch (e) {
      throw AppException('Failed to log mood: $e');
    }
  }

  @override
  Future<void> deleteMood(String id) async {
    try {
      await _client.from('moods').delete().eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete mood: $e');
    }
  }
}

class MoodRepositoryImpl implements MoodRepository {
  final MoodRemoteDatasource _datasource;
  MoodRepositoryImpl(this._datasource);

  @override Future<List<MoodEntry>> getMoods() => _datasource.getMoods();
  @override Future<void> upsertMood(MoodEntry mood) => _datasource.upsertMood(mood);
  @override Future<void> deleteMood(String id) => _datasource.deleteMood(id);
}
