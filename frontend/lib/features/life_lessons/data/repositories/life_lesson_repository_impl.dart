import 'package:chronicle/features/life_lessons/data/datasources/life_lesson_remote_datasource.dart';
import 'package:chronicle/features/life_lessons/domain/models/life_lesson.dart';
import 'package:chronicle/features/life_lessons/domain/repositories/life_lesson_repository.dart';

class LifeLessonRepositoryImpl implements LifeLessonRepository {
  final LifeLessonRemoteDatasource _datasource;

  LifeLessonRepositoryImpl(this._datasource);

  @override
  Future<List<LifeLesson>> getLessons() => _datasource.getLessons();

  @override
  Future<void> createLesson({String? title, required String content, required List<String> tags}) =>
      _datasource.createLesson(title: title, content: content, tags: tags);

  @override
  Future<void> updateLesson(String id, {String? title, required String content, required List<String> tags}) =>
      _datasource.updateLesson(id, title: title, content: content, tags: tags);

  @override
  Future<void> deleteLesson(String id) => _datasource.deleteLesson(id);

  @override
  Future<void> setFavorite(String id, bool isFavorite) => _datasource.setFavorite(id, isFavorite);
}
