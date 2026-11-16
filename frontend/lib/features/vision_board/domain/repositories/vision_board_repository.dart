import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_milestone.dart';

/// Thrown when the `vision_milestones` table doesn't exist yet (migration
/// not run), so the UI can show a notice instead of an error.
class MilestonesUnavailableException extends AppException {
  const MilestonesUnavailableException() : super('Milestones are not set up yet', code: 'milestones_unavailable');
}

abstract class VisionBoardRepository {
  Future<List<VisionGoal>> getGoals();
  Future<void> createGoal(VisionGoal goal);
  Future<void> updateGoal(String id, VisionGoal goal);
  Future<void> deleteGoal(String id);
  Future<void> toggleFavorite(String id, bool currentStatus);

  /// Writes only progress (and status, when given) — no other goal fields.
  Future<void> setGoalProgress(String goalId, int progress, {String? status});

  // ── Milestones ──
  Future<List<VisionMilestone>> getMilestones(String goalId);

  /// Done/total per goal id, for every goal of the user.
  Future<Map<String, MilestoneCount>> getMilestoneCounts();
  Future<VisionMilestone> addMilestone(String goalId, String title, int position);
  Future<void> updateMilestone(String id, {String? title, bool? isDone});
  Future<void> deleteMilestone(String id);

  /// Saves new positions (milestone id → position).
  Future<void> reorderMilestones(Map<String, int> positions);
}
