import 'package:chronicle/features/movies/domain/models/movie.dart';
import 'package:chronicle/features/movies/domain/repositories/movie_repository.dart';
import 'package:chronicle/features/movies/data/datasources/movie_remote_datasource.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDatasource _datasource;

  MovieRepositoryImpl(this._datasource);

  @override
  Future<List<Movie>> getMovies() => _datasource.getMovies();

  @override
  Future<void> createMovie(Movie movie) => _datasource.createMovie(movie);

  @override
  Future<void> updateMovie(String id, Movie movie) => _datasource.updateMovie(id, movie);

  @override
  Future<void> deleteMovie(String id) => _datasource.deleteMovie(id);
}
