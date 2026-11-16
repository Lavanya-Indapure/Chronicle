import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/errors/error_handler.dart';
import 'package:chronicle/core/providers/supabase_provider.dart';
import 'package:chronicle/core/utils/tags.dart';
import 'package:chronicle/features/search/data/datasources/search_remote_datasource.dart';
import 'package:chronicle/features/search/data/repositories/search_repository_impl.dart';
import 'package:chronicle/features/search/domain/repositories/search_repository.dart';
import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/domain/search_module.dart';
import 'package:chronicle/features/search/domain/search_query_builder.dart';

enum SearchStatus { idle, loading, done, error }

class SearchState extends Equatable {
  final SearchRequest request;
  final SearchStatus status;
  final List<SearchModuleResult> results;
  final String? errorMessage;

  /// Tags available to filter by (one spelling each, sorted).
  final List<String> tagOptions;

  /// Every stored spelling, so a tag filter matches all casings.
  final Map<String, Set<String>> tagSpellings;
  final List<SearchCategory> categories;

  const SearchState({
    this.request = const SearchRequest(),
    this.status = SearchStatus.idle,
    this.results = const [],
    this.errorMessage,
    this.tagOptions = const [],
    this.tagSpellings = const {},
    this.categories = const [],
  });

  List<SearchModuleResult> get withItems => results.where((r) => r.items.isNotEmpty).toList();
  List<SearchModule> get failedModules => [for (final r in results) if (r.failed) r.module];
  int get totalCount => results.fold(0, (sum, r) => sum + r.items.length);
  bool get allFailed => results.isNotEmpty && results.every((r) => r.failed);

  SearchState copyWith({
    SearchRequest? request,
    SearchStatus? status,
    List<SearchModuleResult>? results,
    String? errorMessage,
    List<String>? tagOptions,
    Map<String, Set<String>>? tagSpellings,
    List<SearchCategory>? categories,
  }) =>
      SearchState(
        request: request ?? this.request,
        status: status ?? this.status,
        results: results ?? this.results,
        errorMessage: errorMessage,
        tagOptions: tagOptions ?? this.tagOptions,
        tagSpellings: tagSpellings ?? this.tagSpellings,
        categories: categories ?? this.categories,
      );

  @override
  List<Object?> get props => [request, status, results, errorMessage, tagOptions, tagSpellings, categories];
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(SearchRemoteDatasource(ref.watch(supabaseClientProvider)));
});

class GlobalSearchController extends Notifier<SearchState> {
  static const debounce = Duration(milliseconds: 300);

  late SearchRepository _repository;
  Timer? _debounce;

  /// Incremented per search; responses from older searches are dropped.
  int _generation = 0;

  @override
  SearchState build() {
    _repository = ref.watch(searchRepositoryProvider);
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_loadOptions);
    return const SearchState();
  }

  Future<void> _loadOptions() async {
    final results = await Future.wait([_repository.getAllTags(), _repository.getExpenseCategories()]);
    final tags = results[0] as List<String>;
    state = state.copyWith(
      tagOptions: TagUtils.collect([tags]),
      tagSpellings: SearchQueryBuilder.spellingsOf(tags),
      categories: results[1] as List<SearchCategory>,
      errorMessage: state.errorMessage,
    );
  }

  /// Text changes are debounced; filter changes search immediately.
  void setQuery(String query) {
    state = state.copyWith(request: state.request.copyWith(query: query), errorMessage: state.errorMessage);
    _debounce?.cancel();
    _debounce = Timer(debounce, search);
  }

  void toggleModule(SearchModule module) {
    final next = {...state.request.modules};
    if (!next.remove(module)) next.add(module);
    _apply(state.request.copyWith(modules: next));
  }

  void clearModules() => _apply(state.request.copyWith(modules: const {}));

  void setDateRange(SearchDateRange? range) =>
      _apply(range == null ? state.request.copyWith(clearDateRange: true) : state.request.copyWith(dateRange: range));

  void toggleTag(String tag) {
    final next = {...state.request.tags};
    if (!next.remove(tag)) next.add(tag);
    _apply(state.request.copyWith(tags: next));
  }

  void setCategory(String? categoryId) => _apply(
      categoryId == null ? state.request.copyWith(clearCategory: true) : state.request.copyWith(categoryId: categoryId));

  void clearFilters() => _apply(state.request.clearFilters());

  void _apply(SearchRequest request) {
    _debounce?.cancel();
    state = state.copyWith(request: request);
    search();
  }

  /// Runs the current request now.
  Future<void> search() async {
    _debounce?.cancel();
    final generation = ++_generation;
    final plans = SearchQueryBuilder.build(state.request, tagSpellings: state.tagSpellings);
    if (plans.isEmpty) {
      state = state.copyWith(status: SearchStatus.idle, results: const []);
      return;
    }
    state = state.copyWith(status: SearchStatus.loading);
    try {
      final results = await _repository.search(plans);
      if (generation != _generation) return; // a newer search is in flight
      final failed = results.isNotEmpty && results.every((r) => r.failed);
      state = state.copyWith(
        status: failed ? SearchStatus.error : SearchStatus.done,
        results: results,
        errorMessage: failed ? results.first.error : null,
      );
    } catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(status: SearchStatus.error, results: const [], errorMessage: ErrorHandler.handle(e).message);
    }
  }
}

final searchControllerProvider = NotifierProvider.autoDispose<GlobalSearchController, SearchState>(GlobalSearchController.new);
