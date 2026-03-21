import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/first_times/domain/models/first_time_experience.dart';
import 'package:chronicle/features/first_times/domain/repositories/first_time_repository.dart';
import 'package:chronicle/features/first_times/data/datasources/first_time_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class FirstTimeRemoteDatasourceImpl implements FirstTimeRemoteDatasource {
  final SupabaseClient _client;
  FirstTimeRemoteDatasourceImpl(this._client);

  @override
  Future<List<FirstTimeExperience>> getFirstTimes() async {
    try {
      final response = await _client.from('first_times').select().order('log_date', ascending: false);
      return (response as List).map((json) => FirstTimeExperience.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch experiences: $e');
    }
  }

  @override
  Future<void> createFirstTime(FirstTimeExperience experience) async {
    try {
      final data = experience.toJson();
      data['user_id'] = _client.auth.currentUser!.id;
      await _client.from('first_times').insert(data);
    } catch (e) {
      throw AppException('Failed to create experience: $e');
    }
  }

  @override
  Future<void> updateFirstTime(String id, FirstTimeExperience experience) async {
    try {
      await _client.from('first_times').update(experience.toJson()).eq('id', id);
    } catch (e) {
      throw AppException('Failed to update experience: $e');
    }
  }

  @override
  Future<void> deleteFirstTime(String id) async {
    try {
      await _client.from('first_times').delete().eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete experience: $e');
    }
  }
}

class FirstTimeRepositoryImpl implements FirstTimeRepository {
  final FirstTimeRemoteDatasource _datasource;
  FirstTimeRepositoryImpl(this._datasource);

  @override Future<List<FirstTimeExperience>> getFirstTimes() => _datasource.getFirstTimes();
  @override Future<void> createFirstTime(FirstTimeExperience experience) => _datasource.createFirstTime(experience);
  @override Future<void> updateFirstTime(String id, FirstTimeExperience experience) => _datasource.updateFirstTime(id, experience);
  @override Future<void> deleteFirstTime(String id) => _datasource.deleteFirstTime(id);
}
