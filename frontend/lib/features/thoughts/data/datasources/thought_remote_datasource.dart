import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/thoughts/domain/models/thought.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class ThoughtRemoteDatasource {
  final SupabaseClient _client;

  ThoughtRemoteDatasource(this._client);

  Future<List<Thought>> getThoughts() async {
    try {
      final response = await _client.from('thoughts').select().order('created_at', ascending: false);
      return (response as List).map((json) => Thought.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch thoughts: $e');
    }
  }

  Future<void> createThought(String content, List<String> tags) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('thoughts').insert({
        'user_id': userId,
        'content': content,
        'tags': tags,
      });
    } catch (e) {
      throw AppException('Failed to create thought: $e');
    }
  }

  Future<void> updateThought(String id, String content, List<String> tags) async {
    try {
      await _client.from('thoughts').update({
        'content': content,
        'tags': tags,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw AppException('Failed to update thought: $e');
    }
  }

  Future<void> deleteThought(String id) async {
    try {
      await _client.from('thoughts').delete().eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete thought: $e');
    }
  }

  Future<void> toggleFavorite(String id, bool currentStatus) async {
    try {
      await _client.from('thoughts').update({'is_favorite': !currentStatus}).eq('id', id);
    } catch (e) {
      throw AppException('Failed to toggle favorite: $e');
    }
  }
}
