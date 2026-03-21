import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';

abstract class VisionBoardRepository {
  Future<List<VisionGoal>> getGoals();
  Future<void> createGoal(VisionGoal goal);
  Future<void> updateGoal(String id, VisionGoal goal);
  Future<void> deleteGoal(String id);
  Future<void> toggleFavorite(String id, bool currentStatus);
}
