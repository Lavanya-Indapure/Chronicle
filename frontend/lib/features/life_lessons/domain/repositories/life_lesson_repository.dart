import 'package:chronicle/features/life_lessons/domain/models/life_lesson.dart';

abstract class LifeLessonRepository {
  Future<List<LifeLesson>> getLessons();
  Future<void> createLesson({String? title, required String content, required List<String> tags});
  Future<void> updateLesson(String id, {String? title, required String content, required List<String> tags});

  /// Soft delete: the row is kept with `deleted_at` set.
  Future<void> deleteLesson(String id);
  Future<void> setFavorite(String id, bool isFavorite);
}
