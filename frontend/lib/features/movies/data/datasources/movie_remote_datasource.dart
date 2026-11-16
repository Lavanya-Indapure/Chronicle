import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/movies/domain/models/movie.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class MovieRemoteDatasource {
  final SupabaseClient _client;

  MovieRemoteDatasource(this._client);

  Future<List<Movie>> getMovies() async {
    try {
      final response = await _client.from('movies').select().order('watch_date', ascending: false);
      return (response as List).map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch movies: $e');
    }
  }

  Future<void> createMovie(Movie movie) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final movieData = movie.toJson();
      movieData['user_id'] = userId;
      await _client.from('movies').insert(movieData);
    } catch (e) {
      throw AppException('Failed to create movie entry: $e');
    }
  }

  Future<void> updateMovie(String id, Movie movie, {List<String> previousTags = const []}) async {
    try {
      final movieData = movie.toJson(previousTags: previousTags);
      movieData['updated_at'] = DateTime.now().toIso8601String();
      await _client.from('movies').update(movieData).eq('id', id);
    } catch (e) {
      throw AppException('Failed to update movie entry: $e');
    }
  }

  Future<void> deleteMovie(String id) async {
    try {
      await _client.from('movies').delete().eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete movie entry: $e');
    }
  }
}
