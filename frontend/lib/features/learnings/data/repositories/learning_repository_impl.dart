import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/learnings/domain/models/learning.dart';
import 'package:chronicle/features/learnings/domain/repositories/learning_repository.dart';
import 'package:chronicle/features/learnings/data/datasources/learning_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class LearningRemoteDatasourceImpl implements LearningRemoteDatasource {
  final SupabaseClient _client;
  LearningRemoteDatasourceImpl(this._client);

  @override
  Future<List<Learning>> getLearnings() async {
    try {
      final response = await _client.from('learnings').select().order('log_date', ascending: false);
      return (response as List).map((json) => Learning.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch learnings: $e');
    }
  }

  @override
  Future<void> createLearning(Learning learning) async {
    try {
      final data = learning.toJson();
      data['user_id'] = _client.auth.currentUser!.id;
      await _client.from('learnings').insert(data);
    } catch (e) {
      throw AppException('Failed to create learning: $e');
    }
  }

  @override
  Future<void> updateLearning(String id, Learning learning) async {
    try {
      await _client.from('learnings').update(learning.toJson()).eq('id', id);
    } catch (e) {
      throw AppException('Failed to update learning: $e');
    }
  }

  @override
  Future<void> deleteLearning(String id) async {
    try {
      await _client.from('learnings').delete().eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete learning: $e');
    }
  }
}

class LearningRepositoryImpl implements LearningRepository {
  final LearningRemoteDatasource _datasource;
  LearningRepositoryImpl(this._datasource);

  @override Future<List<Learning>> getLearnings() => _datasource.getLearnings();
  @override Future<void> createLearning(Learning learning) => _datasource.createLearning(learning);
  @override Future<void> updateLearning(String id, Learning learning) => _datasource.updateLearning(id, learning);
  @override Future<void> deleteLearning(String id) => _datasource.deleteLearning(id);
}
