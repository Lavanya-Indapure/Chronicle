import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/thoughts/domain/models/thought.dart';
import 'package:chronicle/features/thoughts/domain/repositories/thought_repository.dart';
import 'package:chronicle/features/thoughts/data/repositories/thought_repository_impl.dart';
import 'package:chronicle/features/thoughts/data/datasources/thought_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class ThoughtState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Thought> thoughts;
  final String searchQuery;
  final bool onlyFavorites;
  final String? selectedTag;

  const ThoughtState({
    this.isLoading = false,
    this.errorMessage,
    this.thoughts = const [],
    this.searchQuery = '',
    this.onlyFavorites = false,
    this.selectedTag,
  });

  ThoughtState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Thought>? thoughts,
    String? searchQuery,
    bool? onlyFavorites,
    String? selectedTag,
    bool clearTag = false,
  }) {
    return ThoughtState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      thoughts: thoughts ?? this.thoughts,
      searchQuery: searchQuery ?? this.searchQuery,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
    );
  }

  List<Thought> get filteredThoughts {
    return thoughts.where((t) {
      if (onlyFavorites && !t.isFavorite) return false;
      if (selectedTag != null && !(t.tags?.toLowerCase().contains(selectedTag!.toLowerCase()) ?? false)) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesContent = t.content.toLowerCase().contains(query);
        final matchesTags = t.tags?.toLowerCase().contains(query) ?? false;
        if (!matchesContent && !matchesTags) return false;
      }
      return true;
    }).toList();
  }

  List<String> get allTags {
    final tagsSet = <String>{};
    for (var t in thoughts) {
      if (t.tags != null && t.tags!.isNotEmpty) {
        tagsSet.addAll(t.tags!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
    }
    return tagsSet.toList()..sort();
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, thoughts, searchQuery, onlyFavorites, selectedTag];
}

class ThoughtController extends Notifier<ThoughtState> {
  late final ThoughtRepository _repository;

  @override
  ThoughtState build() {
    final client = Supabase.instance.client;
    final datasource = ThoughtRemoteDatasource(client);
    _repository = ThoughtRepositoryImpl(datasource);
    
    Future.microtask(() => loadThoughts());
    
    return const ThoughtState();
  }

  Future<void> loadThoughts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final thoughts = await _repository.getThoughts();
      state = state.copyWith(thoughts: thoughts, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> createThought(String content, String? tags) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createThought(content, tags);
      await loadThoughts();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> updateThought(String id, String content, String? tags) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateThought(id, content, tags);
      await loadThoughts();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> deleteThought(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteThought(id);
      await loadThoughts();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> toggleFavorite(Thought thought) async {
    try {
      await _repository.toggleFavorite(thought.id, thought.isFavorite);
      await loadThoughts();
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void toggleOnlyFavorites() => state = state.copyWith(onlyFavorites: !state.onlyFavorites);
  void setSelectedTag(String? tag) => state = state.copyWith(selectedTag: tag, clearTag: tag == null);
}

final thoughtControllerProvider = NotifierProvider<ThoughtController, ThoughtState>(ThoughtController.new);
