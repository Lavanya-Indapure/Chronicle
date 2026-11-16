import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_milestone.dart';
import 'package:chronicle/features/vision_board/domain/repositories/vision_board_repository.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class VisionBoardRemoteDatasource {
  /// PostgREST "table not in schema cache" / Postgres "undefined table".
  static const _missingTableCodes = {'PGRST205', '42P01'};

  final SupabaseClient _client;

  VisionBoardRemoteDatasource(this._client);

  String get _userId => _client.auth.currentUser!.id;

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

  Future<void> setGoalProgress(String goalId, int progress, {String? status}) async {
    try {
      await _client.from('vision_board').update({
        'progress': progress,
        'status': ?status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', goalId);
    } catch (e) {
      throw AppException('Failed to update goal progress: $e');
    }
  }

  // ── Milestones ──

  /// Runs a milestones query, mapping a missing table to
  /// [MilestonesUnavailableException].
  Future<T> _milestones<T>(String what, Future<T> Function() query) async {
    try {
      return await query();
    } on PostgrestException catch (e) {
      if (_missingTableCodes.contains(e.code)) throw const MilestonesUnavailableException();
      throw AppException('Failed to $what: ${e.message}', code: e.code, originalError: e);
    } catch (e) {
      throw AppException('Failed to $what: $e', originalError: e);
    }
  }

  Future<List<VisionMilestone>> getMilestones(String goalId) => _milestones('load milestones', () async {
        final rows = await _client
            .from('vision_milestones')
            .select()
            .eq('goal_id', goalId)
            .order('position')
            .order('created_at');
        return rows.map(VisionMilestone.fromJson).toList();
      });

  Future<Map<String, MilestoneCount>> getMilestoneCounts() => _milestones('load milestones', () async {
        final rows = await _client.from('vision_milestones').select('goal_id, is_done').eq('user_id', _userId);
        final done = <String, int>{};
        final total = <String, int>{};
        for (final r in rows) {
          final id = r['goal_id'] as String;
          total[id] = (total[id] ?? 0) + 1;
          if (r['is_done'] == true) done[id] = (done[id] ?? 0) + 1;
        }
        return {for (final id in total.keys) id: MilestoneCount(done: done[id] ?? 0, total: total[id]!)};
      });

  Future<VisionMilestone> addMilestone(String goalId, String title, int position) =>
      _milestones('add milestone', () async {
        final row = await _client
            .from('vision_milestones')
            .insert({'goal_id': goalId, 'user_id': _userId, 'title': title, 'position': position})
            .select()
            .single();
        return VisionMilestone.fromJson(row);
      });

  Future<void> updateMilestone(String id, {String? title, bool? isDone}) => _milestones('update milestone', () async {
        await _client.from('vision_milestones').update({
          'title': ?title,
          if (isDone != null) ...{
            'is_done': isDone,
            'done_at': isDone ? DateTime.now().toUtc().toIso8601String() : null,
          },
        }).eq('id', id);
      });

  Future<void> deleteMilestone(String id) => _milestones('delete milestone', () async {
        await _client.from('vision_milestones').delete().eq('id', id);
      });

  Future<void> reorderMilestones(Map<String, int> positions) => _milestones('reorder milestones', () async {
        await Future.wait([
          for (final e in positions.entries)
            _client.from('vision_milestones').update({'position': e.value}).eq('id', e.key),
        ]);
      });
}
