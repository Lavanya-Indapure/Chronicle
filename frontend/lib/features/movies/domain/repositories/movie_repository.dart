import 'package:chronicle/features/movies/domain/models/movie.dart';

abstract class MovieRepository {
  Future<List<Movie>> getMovies();
  Future<void> createMovie(Movie movie);
  Future<void> updateMovie(String id, Movie movie, {List<String> previousTags});
  Future<void> deleteMovie(String id);
}
