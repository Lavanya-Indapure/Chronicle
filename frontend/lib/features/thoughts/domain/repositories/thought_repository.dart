import 'package:chronicle/features/thoughts/domain/models/thought.dart';

abstract class ThoughtRepository {
  Future<List<Thought>> getThoughts();
  Future<void> createThought(String content, List<String> tags);
  Future<void> updateThought(String id, String content, List<String> tags);
  Future<void> deleteThought(String id);
  Future<void> toggleFavorite(String id, bool currentStatus);
}
