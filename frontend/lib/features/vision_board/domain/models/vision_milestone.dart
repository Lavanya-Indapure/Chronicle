import 'package:equatable/equatable.dart';

/// One step towards a vision goal (`vision_milestones`).
class VisionMilestone extends Equatable {
  final String id;
  final String goalId;
  final String title;
  final bool isDone;
  final DateTime? doneAt;
  final int position;

  const VisionMilestone({
    required this.id,
    required this.goalId,
    required this.title,
    this.isDone = false,
    this.doneAt,
    required this.position,
  });

  factory VisionMilestone.fromJson(Map<String, dynamic> json) => VisionMilestone(
        id: json['id'] as String,
        goalId: json['goal_id'] as String,
        title: json['title'] as String,
        isDone: json['is_done'] as bool? ?? false,
        doneAt: json['done_at'] != null ? DateTime.parse(json['done_at'] as String) : null,
        position: (json['position'] as num?)?.toInt() ?? 0,
      );

  VisionMilestone copyWith({String? id, String? title, bool? isDone, int? position}) {
    final done = isDone ?? this.isDone;
    return VisionMilestone(
      id: id ?? this.id,
      goalId: goalId,
      title: title ?? this.title,
      isDone: done,
      doneAt: done ? (this.isDone ? doneAt : DateTime.now()) : null,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props => [id, goalId, title, isDone, doneAt, position];
}

/// "3 of 5 done" for a goal.
class MilestoneCount extends Equatable {
  final int done;
  final int total;

  const MilestoneCount({required this.done, required this.total});

  static MilestoneCount of(List<VisionMilestone> items) =>
      MilestoneCount(done: items.where((m) => m.isDone).length, total: items.length);

  @override
  List<Object?> get props => [done, total];
}
