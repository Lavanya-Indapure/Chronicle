import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/features/vision_board/domain/milestone_progress.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_milestone.dart';
import 'package:chronicle/features/vision_board/domain/repositories/vision_board_repository.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';

class MilestonesState extends Equatable {
  final bool isLoading;

  /// The `vision_milestones` table doesn't exist yet.
  final bool unavailable;
  final List<VisionMilestone> items;
  final String? errorMessage;

  const MilestonesState({this.isLoading = false, this.unavailable = false, this.items = const [], this.errorMessage});

  int? get progress => MilestoneProgress.percent(items);
  MilestoneCount get count => MilestoneCount.of(items);

  MilestonesState copyWith({bool? isLoading, bool? unavailable, List<VisionMilestone>? items, String? errorMessage}) =>
      MilestonesState(
        isLoading: isLoading ?? this.isLoading,
        unavailable: unavailable ?? this.unavailable,
        items: items ?? this.items,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [isLoading, unavailable, items, errorMessage];
}

/// Milestones of one goal. Every change is shown immediately, saved, and
/// rolled back if saving fails; the goal's progress/status follow
/// [MilestoneProgress] and are written back to `vision_board`.
class MilestonesController extends Notifier<MilestonesState> {
  final String goalId;
  late VisionBoardRepository _repository;
  int _tempIds = 0;

  MilestonesController(this.goalId);

  @override
  MilestonesState build() {
    _repository = ref.watch(visionBoardRepositoryProvider);
    Future.microtask(load);
    return const MilestonesState(isLoading: true);
  }

  Future<void> load() async {
    try {
      final items = await _repository.getMilestones(goalId);
      state = MilestonesState(items: [...items]..sort((a, b) => a.position.compareTo(b.position)));
    } on MilestonesUnavailableException {
      state = const MilestonesState(unavailable: true);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<bool> add(String title) async {
    final text = title.trim();
    if (text.isEmpty) return false;
    final position = state.items.isEmpty ? 0 : state.items.map((m) => m.position).reduce((a, b) => a > b ? a : b) + 1;
    final temp = VisionMilestone(id: 'tmp-${_tempIds++}', goalId: goalId, title: text, position: position);
    return _mutate([...state.items, temp], () async {
      final saved = await _repository.addMilestone(goalId, text, position);
      state = state.copyWith(items: [for (final m in state.items) m.id == temp.id ? saved : m]);
    });
  }

  Future<bool> toggle(VisionMilestone milestone) {
    final next = milestone.copyWith(isDone: !milestone.isDone);
    return _mutate(
      _replace(milestone.id, next),
      () => _repository.updateMilestone(milestone.id, isDone: next.isDone),
    );
  }

  Future<bool> rename(VisionMilestone milestone, String title) {
    final text = title.trim();
    if (text.isEmpty || text == milestone.title) return Future.value(false);
    return _mutate(
      _replace(milestone.id, milestone.copyWith(title: text)),
      () => _repository.updateMilestone(milestone.id, title: text),
    );
  }

  Future<bool> delete(VisionMilestone milestone) => _mutate(
        state.items.where((m) => m.id != milestone.id).toList(),
        () => _repository.deleteMilestone(milestone.id),
      );

  Future<bool> reorder(int oldIndex, int newIndex) {
    final next = MilestoneProgress.reorder(state.items, oldIndex, newIndex);
    final before = {for (final m in state.items) m.id: m.position};
    final changed = {for (final m in next) if (before[m.id] != m.position) m.id: m.position};
    if (changed.isEmpty) return Future.value(true);
    return _mutate(next, () => _repository.reorderMilestones(changed), syncProgress: false);
  }

  List<VisionMilestone> _replace(String id, VisionMilestone next) => [for (final m in state.items) m.id == id ? next : m];

  /// Shows [next] now, then runs [persist]; on failure restores the previous
  /// milestones and goal. On success writes the goal's new progress/status.
  Future<bool> _mutate(List<VisionMilestone> next, Future<void> Function() persist, {bool syncProgress = true}) async {
    final board = ref.read(visionBoardControllerProvider.notifier);
    final previousItems = state.items;
    final previousGoal = _goal();

    state = state.copyWith(items: next);
    final update = syncProgress ? _goalUpdate(previousGoal, next) : null;
    if (update != null) board.applyMilestoneProgress(goalId, progress: update.$1, status: update.$2, count: MilestoneCount.of(next));

    try {
      await persist();
    } on AppException catch (e) {
      state = state.copyWith(items: previousItems, errorMessage: e.message);
      if (update != null) {
        board.applyMilestoneProgress(
          goalId,
          progress: previousGoal?.progress,
          status: previousGoal?.status,
          count: MilestoneCount.of(previousItems),
        );
      }
      return false;
    }

    if (update != null && update.$1 != null) {
      try {
        await _repository.setGoalProgress(goalId, update.$1!, status: update.$2);
      } on AppException catch (e) {
        // The milestone itself is saved; only the goal's cached progress
        // lagged. Keep the change and say so — the next change retries.
        state = state.copyWith(errorMessage: e.message);
      }
    }
    return true;
  }

  VisionGoal? _goal() => ref.read(visionBoardControllerProvider).goalById(goalId);

  /// New (progress, status) for the goal, or (null, null) when only the
  /// count changes (all milestones removed: progress goes back to manual
  /// and keeps its last value).
  (int?, String?)? _goalUpdate(VisionGoal? goal, List<VisionMilestone> items) {
    final progress = MilestoneProgress.percent(items);
    if (progress == null) return (null, null);
    final status = goal == null ? null : MilestoneProgress.statusFor(current: goal.status, progress: progress);
    return (progress, status);
  }
}

final milestonesProvider =
    NotifierProvider.autoDispose.family<MilestonesController, MilestonesState, String>(MilestonesController.new);
