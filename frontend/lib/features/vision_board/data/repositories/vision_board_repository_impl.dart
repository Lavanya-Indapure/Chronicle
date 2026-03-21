import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
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
}
