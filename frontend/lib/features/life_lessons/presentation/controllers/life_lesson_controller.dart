import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/core/providers/supabase_provider.dart';
import 'package:chronicle/features/life_lessons/data/datasources/life_lesson_remote_datasource.dart';
import 'package:chronicle/features/life_lessons/data/repositories/life_lesson_repository_impl.dart';
import 'package:chronicle/features/life_lessons/domain/models/life_lesson.dart';
import 'package:chronicle/features/life_lessons/domain/repositories/life_lesson_repository.dart';

// ── State ──
class LifeLessonState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<LifeLesson> lessons;
  final String searchQuery;
  final bool onlyFavorites;
  final String? selectedTag;

  const LifeLessonState({
    this.isLoading = false,
    this.errorMessage,
    this.lessons = const [],
    this.searchQuery = '',
    this.onlyFavorites = false,
    this.selectedTag,
  });

  /// [errorMessage] is cleared on every copy unless passed again.
  LifeLessonState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<LifeLesson>? lessons,
    String? searchQuery,
    bool? onlyFavorites,
    String? selectedTag,
    bool clearTag = false,
  }) {
    return LifeLessonState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lessons: lessons ?? this.lessons,
      searchQuery: searchQuery ?? this.searchQuery,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
    );
  }

  /// Lessons matching the favourites toggle, selected tag and search text
  /// (title, content or tags).
  List<LifeLesson> get filteredLessons {
    final query = searchQuery.trim().toLowerCase();
    final tag = selectedTag?.toLowerCase();
    return lessons.where((l) {
      if (onlyFavorites && !l.isFavorite) return false;
      if (tag != null && !l.tags.any((t) => t.toLowerCase() == tag)) return false;
      if (query.isEmpty) return true;
      return l.content.toLowerCase().contains(query) ||
          (l.title?.toLowerCase().contains(query) ?? false) ||
          l.tags.any((t) => t.toLowerCase().contains(query));
    }).toList();
  }

  /// Every tag in use, de-duplicated case-insensitively and sorted.
  List<String> get allTags {
    final byLower = <String, String>{};
    for (final l in lessons) {
      for (final t in l.tags) {
        byLower.putIfAbsent(t.toLowerCase(), () => t);
      }
    }
    return byLower.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, lessons, searchQuery, onlyFavorites, selectedTag];
}

// ── DI ──
final lifeLessonRepositoryProvider = Provider<LifeLessonRepository>((ref) {
  return LifeLessonRepositoryImpl(LifeLessonRemoteDatasource(ref.watch(supabaseClientProvider)));
});

final lifeLessonControllerProvider =
    NotifierProvider<LifeLessonController, LifeLessonState>(LifeLessonController.new);

// ── Controller ──
class LifeLessonController extends Notifier<LifeLessonState> {
  LifeLessonRepository get _repository => ref.read(lifeLessonRepositoryProvider);

  @override
  LifeLessonState build() {
    Future.microtask(loadLessons);
    return const LifeLessonState(isLoading: true);
  }

  Future<void> loadLessons() async {
    state = state.copyWith(isLoading: true);
    try {
      final lessons = await _repository.getLessons();
      state = state.copyWith(isLoading: false, lessons: lessons);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Returns true on success; on failure sets [LifeLessonState.errorMessage].
  Future<bool> saveLesson({String? id, String? title, required String content, required List<String> tags}) async {
    try {
      if (id == null) {
        await _repository.createLesson(title: title, content: content, tags: tags);
      } else {
        await _repository.updateLesson(id, title: title, content: content, tags: tags);
      }
      await loadLessons();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  /// Removes the lesson from the list immediately; restores it if the
  /// delete fails.
  Future<bool> deleteLesson(String id) async {
    final previous = state.lessons;
    state = state.copyWith(lessons: previous.where((l) => l.id != id).toList());
    try {
      await _repository.deleteLesson(id);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(lessons: previous, errorMessage: e.message);
      return false;
    }
  }

  /// Flips the heart immediately; reverts if saving fails.
  Future<void> toggleFavorite(LifeLesson lesson) async {
    final previous = state.lessons;
    state = state.copyWith(
      lessons: [for (final l in previous) l.id == lesson.id ? l.copyWith(isFavorite: !l.isFavorite) : l],
    );
    try {
      await _repository.setFavorite(lesson.id, !lesson.isFavorite);
    } on AppException catch (e) {
      state = state.copyWith(lessons: previous, errorMessage: e.message);
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void toggleOnlyFavorites() => state = state.copyWith(onlyFavorites: !state.onlyFavorites);
  void setSelectedTag(String? tag) => state = state.copyWith(selectedTag: tag, clearTag: tag == null);
}
