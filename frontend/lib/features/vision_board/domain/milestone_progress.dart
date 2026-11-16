import 'package:chronicle/features/vision_board/domain/models/vision_milestone.dart';

/// Goal status values as stored in `vision_board.status`.
abstract final class GoalStatus {
  static const notStarted = 'not_started';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
}

/// How milestones drive a goal's progress and status.
///
/// - Progress is done ÷ total, rounded, but only reaches 100 when every
///   milestone is done (so 199 of 200 shows 99, not 100).
/// - Status follows the work, never jumps to "completed" on its own:
///   * the first ticked milestone moves "not started" to "in progress";
///   * a "completed" goal with any unfinished milestone (one unticked, or a
///     new one added) goes back to "in progress" — a goal can't be achieved
///     while steps remain;
///   * reaching 100% leaves the status alone; the user is offered (not
///     forced) to mark the goal achieved.
abstract final class MilestoneProgress {
  /// Null when there are no milestones (progress is then set by hand).
  static int? percent(List<VisionMilestone> items) {
    if (items.isEmpty) return null;
    final done = items.where((m) => m.isDone).length;
    if (done == items.length) return 100;
    final value = (done * 100 / items.length).round();
    return value > 99 ? 99 : value;
  }

  static String statusFor({required String current, required int progress}) {
    if (current == GoalStatus.completed && progress < 100) return GoalStatus.inProgress;
    if (current == GoalStatus.notStarted && progress > 0) return GoalStatus.inProgress;
    return current;
  }

  /// Whether to suggest marking the goal achieved.
  static bool offerCompletion({required List<VisionMilestone> items, required String status}) =>
      items.isNotEmpty && items.every((m) => m.isDone) && status != GoalStatus.completed;

  /// Moves the item at [oldIndex] to [newIndex] (ReorderableListView
  /// semantics: [newIndex] counts the item still in place) and renumbers
  /// positions 0..n-1.
  static List<VisionMilestone> reorder(List<VisionMilestone> items, int oldIndex, int newIndex) {
    final list = [...items];
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    list.insert(target, list.removeAt(oldIndex));
    return [for (var i = 0; i < list.length; i++) list[i].copyWith(position: i)];
  }
}
