import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/features/life_lessons/domain/models/life_lesson.dart';

/// Supabase calls for the `life_lessons` table. Deleted rows (non-null
/// `deleted_at`) are never returned.
class LifeLessonRemoteDatasource {
  static const _table = 'life_lessons';

  final SupabaseClient _client;

  LifeLessonRemoteDatasource(this._client);

  Future<List<LifeLesson>> getLessons() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);
      return (response as List).map((json) => LifeLesson.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw AppException('Failed to fetch life lessons: $e', originalError: e);
    }
  }

  Future<void> createLesson({String? title, required String content, required List<String> tags}) async {
    try {
      await _client.from(_table).insert({
        'user_id': _client.auth.currentUser!.id,
        'title': title,
        'content': content,
        'tags': tags,
      });
    } catch (e) {
      throw AppException('Failed to save life lesson: $e', originalError: e);
    }
  }

  Future<void> updateLesson(String id, {String? title, required String content, required List<String> tags}) async {
    try {
      await _client.from(_table).update({'title': title, 'content': content, 'tags': tags}).eq('id', id);
    } catch (e) {
      throw AppException('Failed to update life lesson: $e', originalError: e);
    }
  }

  Future<void> deleteLesson(String id) async {
    try {
      await _client
          .from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete life lesson: $e', originalError: e);
    }
  }

  Future<void> setFavorite(String id, bool isFavorite) async {
    try {
      await _client.from(_table).update({'is_favorite': isFavorite}).eq('id', id);
    } catch (e) {
      throw AppException('Failed to update favourite: $e', originalError: e);
    }
  }
}
