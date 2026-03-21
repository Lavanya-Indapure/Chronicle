import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/domain/repositories/vision_board_repository.dart';
import 'package:chronicle/features/vision_board/data/repositories/vision_board_repository_impl.dart';
import 'package:chronicle/features/vision_board/data/datasources/vision_board_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

enum VisionSort {
  deadline,
  progress,
  recency,
}

class VisionBoardState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<VisionGoal> goals;
  final String searchQuery;
  final String? statusFilter;
  final String? categoryFilter;
  final bool onlyFavorites;
  final VisionSort sortBy;

  const VisionBoardState({
    this.isLoading = false,
    this.errorMessage,
    this.goals = const [],
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
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      categoryFilter: clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sortBy: sortBy ?? this.sortBy,
    );
  }

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
  List<Object?> get props => [isLoading, errorMessage, goals, searchQuery, statusFilter, categoryFilter, onlyFavorites, sortBy];
}

class VisionBoardController extends Notifier<VisionBoardState> {
  late final VisionBoardRepository _repository;

  @override
  VisionBoardState build() {
    final client = Supabase.instance.client;
    final datasource = VisionBoardRemoteDatasource(client);
    _repository = VisionBoardRepositoryImpl(datasource);
    
    Future.microtask(() => loadGoals());
    
    return const VisionBoardState();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final goals = await _repository.getGoals();
      state = state.copyWith(goals: goals, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
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
      // Logic: progress 100 auto-completes status
      var updatedGoal = goal;
      if (goal.progress == 100) {
        updatedGoal = VisionGoal(
          id: goal.id,
          userId: goal.userId,
          title: goal.title,
          description: goal.description,
          category: goal.category,
          duration: goal.duration,
          targetDate: goal.targetDate,
          plan: goal.plan,
          progress: 100,
          status: 'completed',
          isFavorite: goal.isFavorite,
          createdAt: goal.createdAt,
          updatedAt: goal.updatedAt,
        );
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

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setStatusFilter(String? status) => state = state.copyWith(statusFilter: status, clearStatus: status == null);
  void setCategoryFilter(String? category) => state = state.copyWith(categoryFilter: category, clearCategory: category == null);
  void toggleOnlyFavorites() => state = state.copyWith(onlyFavorites: !state.onlyFavorites);
  void setSortBy(VisionSort sort) => state = state.copyWith(sortBy: sort);
}

final visionBoardControllerProvider = NotifierProvider<VisionBoardController, VisionBoardState>(VisionBoardController.new);
