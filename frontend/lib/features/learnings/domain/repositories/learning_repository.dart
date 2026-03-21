import 'package:chronicle/features/learnings/domain/models/learning.dart';

abstract class LearningRepository {
  Future<List<Learning>> getLearnings();
  Future<void> createLearning(Learning learning);
  Future<void> updateLearning(String id, Learning learning);
  Future<void> deleteLearning(String id);
}
