import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/learnings/domain/models/learning.dart';
import 'package:chronicle/features/learnings/data/repositories/learning_repository_impl.dart';

class LearningState extends Equatable {
  final bool isLoading;
  final List<Learning> learnings;
  final String searchQuery;
  
  const LearningState({
    this.isLoading = false,
    this.learnings = const [],
    this.searchQuery = '',
  });

  List<Learning> get filteredLearnings {
    if (searchQuery.isEmpty) return learnings;
    return learnings.where((l) => 
      l.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
      (l.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  LearningState copyWith({bool? isLoading, List<Learning>? learnings, String? searchQuery}) {
    return LearningState(
      isLoading: isLoading ?? this.isLoading,
      learnings: learnings ?? this.learnings,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override List<Object?> get props => [isLoading, learnings, searchQuery];
}

final learningRepositoryProvider = Provider((ref) {
  return LearningRepositoryImpl(LearningRemoteDatasourceImpl(Supabase.instance.client));
});

class LearningController extends Notifier<LearningState> {
  late final LearningRepositoryImpl _repository;

  @override
  LearningState build() {
    _repository = ref.watch(learningRepositoryProvider);
    _loadLearnings();
    return const LearningState();
  }

  Future<void> _loadLearnings() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await _repository.getLearnings();
      state = state.copyWith(isLoading: false, learnings: results);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);

  Future<void> addLearning(Learning learning) async {
    await _repository.createLearning(learning);
    _loadLearnings();
  }

  /// Removes the entry immediately (a swiped card must leave the list),
  /// then deletes it; restores it if the delete fails.
  Future<void> deleteLearning(String id) async {
    final previous = state.learnings;
    state = state.copyWith(learnings: previous.where((l) => l.id != id).toList());
    try {
      await _repository.deleteLearning(id);
    } catch (_) {
      state = state.copyWith(learnings: previous);
    }
  }
}

final learningControllerProvider = NotifierProvider<LearningController, LearningState>(LearningController.new);
