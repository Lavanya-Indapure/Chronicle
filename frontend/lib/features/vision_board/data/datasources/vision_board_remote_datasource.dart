import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class VisionBoardRemoteDatasource {
  final SupabaseClient _client;

  VisionBoardRemoteDatasource(this._client);

  Future<List<VisionGoal>> getGoals() async {
    try {
      final response = await _client.from('vision_board').select().order('updated_at', ascending: false);
      return (response as List).map((json) => VisionGoal.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch vision goals: $e');
    }
  }

  Future<void> createGoal(VisionGoal goal) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final goalData = goal.toJson();
      goalData['user_id'] = userId;
      await _client.from('vision_board').insert(goalData);
    } catch (e) {
      throw AppException('Failed to create vision goal: $e');
    }
  }

  Future<void> updateGoal(String id, VisionGoal goal) async {
    try {
      final goalData = goal.toJson();
      goalData['updated_at'] = DateTime.now().toIso8601String();
      await _client.from('vision_board').update(goalData).eq('id', id);
    } catch (e) {
      throw AppException('Failed to update vision goal: $e');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _client.from('vision_board').delete().eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete vision goal: $e');
    }
  }

  Future<void> toggleFavorite(String id, bool currentStatus) async {
    try {
      await _client.from('vision_board').update({'is_favorite': !currentStatus}).eq('id', id);
    } catch (e) {
      throw AppException('Failed to toggle favorite: $e');
    }
  }
}
