import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_milestone.dart';
import 'package:chronicle/features/vision_board/domain/repositories/vision_board_repository.dart';
import 'package:chronicle/features/vision_board/data/datasources/vision_board_remote_datasource.dart';

class VisionBoardRepositoryImpl implements VisionBoardRepository {
  final VisionBoardRemoteDatasource _datasource;

  VisionBoardRepositoryImpl(this._datasource);

  @override
  Future<List<VisionGoal>> getGoals() => _datasource.getGoals();

  @override
  Future<void> createGoal(VisionGoal goal) => _datasource.createGoal(goal);

  @override
  Future<void> updateGoal(String id, VisionGoal goal) => _datasource.updateGoal(id, goal);

  @override
  Future<void> deleteGoal(String id) => _datasource.deleteGoal(id);

  @override
  Future<void> toggleFavorite(String id, bool currentStatus) => _datasource.toggleFavorite(id, currentStatus);

  @override
  Future<void> setGoalProgress(String goalId, int progress, {String? status}) =>
      _datasource.setGoalProgress(goalId, progress, status: status);

  @override
  Future<List<VisionMilestone>> getMilestones(String goalId) => _datasource.getMilestones(goalId);

  @override
  Future<Map<String, MilestoneCount>> getMilestoneCounts() => _datasource.getMilestoneCounts();

  @override
  Future<VisionMilestone> addMilestone(String goalId, String title, int position) =>
      _datasource.addMilestone(goalId, title, position);

  @override
  Future<void> updateMilestone(String id, {String? title, bool? isDone}) =>
      _datasource.updateMilestone(id, title: title, isDone: isDone);

  @override
  Future<void> deleteMilestone(String id) => _datasource.deleteMilestone(id);

  @override
  Future<void> reorderMilestones(Map<String, int> positions) => _datasource.reorderMilestones(positions);
}
