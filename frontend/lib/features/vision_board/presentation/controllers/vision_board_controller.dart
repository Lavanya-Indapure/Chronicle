import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/vision_board/domain/milestone_progress.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_milestone.dart';
import 'package:chronicle/features/vision_board/domain/repositories/vision_board_repository.dart';
import 'package:chronicle/features/vision_board/data/repositories/vision_board_repository_impl.dart';
import 'package:chronicle/features/vision_board/data/datasources/vision_board_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

enum VisionSort {
  deadline,
  progress,
  recency,
}

final visionBoardRepositoryProvider = Provider<VisionBoardRepository>((ref) {
  return VisionBoardRepositoryImpl(VisionBoardRemoteDatasource(Supabase.instance.client));
});

class VisionBoardState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<VisionGoal> goals;

  /// Milestone done/total per goal id; goals without milestones are absent.
  final Map<String, MilestoneCount> milestoneCounts;
  final String searchQuery;
  final String? statusFilter;
  final String? categoryFilter;
  final bool onlyFavorites;
  final VisionSort sortBy;

  const VisionBoardState({
    this.isLoading = false,
    this.errorMessage,
    this.goals = const [],
    this.milestoneCounts = const {},
    this.searchQuery = '',
    this.statusFilter,
    this.categoryFilter,
    this.onlyFavorites = false,
    this.sortBy = VisionSort.recency,
  });

  VisionBoardState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<VisionGoal>? goals,
    Map<String, MilestoneCount>? milestoneCounts,
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
    bool? onlyFavorites,
    VisionSort? sortBy,
    bool clearStatus = false,
    bool clearCategory = false,
  }) {
    return VisionBoardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      goals: goals ?? this.goals,
      milestoneCounts: milestoneCounts ?? this.milestoneCounts,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      categoryFilter: clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  VisionGoal? goalById(String id) => goals.where((g) => g.id == id).firstOrNull;

  List<VisionGoal> get filteredGoals {
    var list = goals.where((g) {
      if (onlyFavorites && !g.isFavorite) return false;
      if (statusFilter != null && g.status != statusFilter) return false;
      if (categoryFilter != null && g.category != categoryFilter) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!g.title.toLowerCase().contains(query) &&
            !(g.category?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (sortBy) {
      case VisionSort.deadline:
        list.sort((a, b) {
          if (a.targetDate == null) return 1;
          if (b.targetDate == null) return -1;
          return a.targetDate!.compareTo(b.targetDate!);
        });
        break;
      case VisionSort.progress:
        list.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case VisionSort.recency:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    return list;
  }

  List<String> get allCategories {
    final set = <String>{};
    for (var g in goals) {
      if (g.category != null) set.add(g.category!);
    }
    return set.toList()..sort();
  }

  @override
  List<Object?> get props =>
      [isLoading, errorMessage, goals, milestoneCounts, searchQuery, statusFilter, categoryFilter, onlyFavorites, sortBy];
}

class VisionBoardController extends Notifier<VisionBoardState> {
  late final VisionBoardRepository _repository;

  @override
  VisionBoardState build() {
    _repository = ref.watch(visionBoardRepositoryProvider);

    Future.microtask(() => loadGoals());

    return const VisionBoardState();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([_repository.getGoals(), _loadCounts()]);
      state = state.copyWith(
        goals: results[0] as List<VisionGoal>,
        milestoneCounts: results[1] as Map<String, MilestoneCount>,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Milestone counts are a nice-to-have on the list: if they can't load
  /// (e.g. the table isn't set up yet) the goals still show.
  Future<Map<String, MilestoneCount>> _loadCounts() async {
    try {
      return await _repository.getMilestoneCounts();
    } on AppException {
      return state.milestoneCounts;
    }
  }

  Future<void> createGoal(VisionGoal goal) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createGoal(goal);
      await loadGoals();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> updateGoal(String id, VisionGoal goal) async {
    state = state.copyWith(isLoading: true);
    try {
      // Setting progress to 100 auto-completes the goal — only when progress
      // newly reaches 100, so editing other fields of a goal already at 100
      // (e.g. via milestones) keeps the status the user chose.
      final previous = state.goalById(id);
      var updatedGoal = goal;
      if (goal.progress == 100 && previous?.progress != 100) {
        updatedGoal = goal.copyWith(status: GoalStatus.completed);
      }
      await _repository.updateGoal(id, updatedGoal);
      await loadGoals();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> deleteGoal(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteGoal(id);
      await loadGoals();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> toggleFavorite(VisionGoal goal) async {
    try {
      await _repository.toggleFavorite(goal.id, goal.isFavorite);
      await loadGoals();
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  /// Local update after milestones change (the milestones controller saves
  /// it); keeps the list card and details screen in step without a reload.
  void applyMilestoneProgress(String goalId, {int? progress, String? status, required MilestoneCount count}) {
    final counts = {...state.milestoneCounts};
    if (count.total == 0) {
      counts.remove(goalId);
    } else {
      counts[goalId] = count;
    }
    state = state.copyWith(
      milestoneCounts: counts,
      goals: [
        for (final g in state.goals) g.id == goalId ? g.copyWith(progress: progress, status: status) : g,
      ],
    );
  }

  /// "Mark as achieved" from the milestones prompt.
  Future<void> markCompleted(VisionGoal goal) async {
    final previous = state.goals;
    state = state.copyWith(goals: [
      for (final g in state.goals) g.id == goal.id ? g.copyWith(progress: 100, status: GoalStatus.completed) : g,
    ]);
    try {
      await _repository.setGoalProgress(goal.id, 100, status: GoalStatus.completed);
    } on AppException catch (e) {
      state = state.copyWith(goals: previous, errorMessage: e.message);
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setStatusFilter(String? status) => state = state.copyWith(statusFilter: status, clearStatus: status == null);
  void setCategoryFilter(String? category) => state = state.copyWith(categoryFilter: category, clearCategory: category == null);
  void toggleOnlyFavorites() => state = state.copyWith(onlyFavorites: !state.onlyFavorites);
  void setSortBy(VisionSort sort) => state = state.copyWith(sortBy: sort);
}

final visionBoardControllerProvider = NotifierProvider<VisionBoardController, VisionBoardState>(VisionBoardController.new);
