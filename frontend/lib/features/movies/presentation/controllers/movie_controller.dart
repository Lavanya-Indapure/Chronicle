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

  const MovieState({
    this.isLoading = false,
    this.errorMessage,
    this.movies = const [],
    this.searchQuery = '',
  });

  MovieState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Movie>? movies,
    String? searchQuery,
  }) {
    return MovieState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      movies: movies ?? this.movies,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Movie> get filteredMovies {
    if (searchQuery.isEmpty) return movies;
    return movies.where((m) => m.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, movies, searchQuery];
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

  Future<void> createMovie(Movie movie) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createMovie(movie);
      await loadMovies();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> updateMovie(String id, Movie movie) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateMovie(id, movie);
      await loadMovies();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> deleteMovie(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteMovie(id);
      await loadMovies();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
}

final movieControllerProvider = NotifierProvider<MovieController, MovieState>(MovieController.new);
