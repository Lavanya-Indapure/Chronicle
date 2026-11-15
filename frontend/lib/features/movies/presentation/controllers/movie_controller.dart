import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/movies/domain/models/movie.dart';
import 'package:chronicle/features/movies/domain/repositories/movie_repository.dart';
import 'package:chronicle/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:chronicle/features/movies/data/datasources/movie_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class MovieState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Movie> movies;
  final String searchQuery;

  /// 'theatre', 'mobile-laptop', or null for all.
  final String? platformFilter;

  const MovieState({
    this.isLoading = false,
    this.errorMessage,
    this.movies = const [],
    this.searchQuery = '',
    this.platformFilter,
  });

  MovieState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Movie>? movies,
    String? searchQuery,
    String? platformFilter,
    bool clearPlatform = false,
  }) {
    return MovieState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      movies: movies ?? this.movies,
      searchQuery: searchQuery ?? this.searchQuery,
      platformFilter: clearPlatform ? null : (platformFilter ?? this.platformFilter),
    );
  }

  /// Search + platform filter applied, newest watch first.
  List<Movie> get filteredMovies {
    final query = searchQuery.toLowerCase();
    return movies
        .where((m) => platformFilter == null || m.platform == platformFilter)
        .where((m) => query.isEmpty || m.name.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => b.watchDate.compareTo(a.watchDate));
  }

  int countFor(String? platform) => platform == null ? movies.length : movies.where((m) => m.platform == platform).length;

  bool get hasActiveFilters => searchQuery.isNotEmpty || platformFilter != null;

  List<Movie> get _thisYear => movies.where((m) => m.watchDate.year == DateTime.now().year).toList();

  int get watchedThisYear => _thisYear.length;

  double get theatreSpendThisYear =>
      _thisYear.where((m) => m.platform == 'theatre').fold(0.0, (sum, m) => sum + (m.cost ?? 0));

  @override
  List<Object?> get props => [isLoading, errorMessage, movies, searchQuery, platformFilter];
}

class MovieController extends Notifier<MovieState> {
  late final MovieRepository _repository;

  @override
  MovieState build() {
    final client = Supabase.instance.client;
    final datasource = MovieRemoteDatasource(client);
    _repository = MovieRepositoryImpl(datasource);
    
    Future.microtask(() => loadMovies());
    
    return const MovieState();
  }

  Future<void> loadMovies() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final movies = await _repository.getMovies();
      state = state.copyWith(movies: movies, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<bool> createMovie(Movie movie) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createMovie(movie);
      await loadMovies();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> updateMovie(String id, Movie movie) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateMovie(id, movie);
      await loadMovies();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> deleteMovie(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteMovie(id);
      await loadMovies();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setPlatformFilter(String? platform) =>
      state = state.copyWith(platformFilter: platform, clearPlatform: platform == null);
}

final movieControllerProvider = NotifierProvider<MovieController, MovieState>(MovieController.new);
