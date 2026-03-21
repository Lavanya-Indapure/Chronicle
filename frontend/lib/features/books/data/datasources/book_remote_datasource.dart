import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/books/domain/models/book.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class BookRemoteDatasource {
  final SupabaseClient _client;

  BookRemoteDatasource(this._client);

  Future<List<Book>> getBooks() async {
    try {
      final response = await _client.from('books').select().order('updated_at', ascending: false);
      return (response as List).map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      throw AppException('Failed to fetch books: $e');
    }
  }

  Future<void> createBook({
    required String name,
    String? author,
    String? takeaways,
    String status = 'reading',
    double? rating,
    bool isFavorite = false,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('books').insert({
        'user_id': userId,
        'name': name,
        'author': author,
        'takeaways': takeaways,
        'status': status,
        'rating': rating,
        'is_favorite': isFavorite,
      });
    } catch (e) {
      throw AppException('Failed to create book: $e');
    }
  }

  Future<void> updateBook({
    required String id,
    required String name,
    String? author,
    String? takeaways,
    required String status,
    double? rating,
    required bool isFavorite,
  }) async {
    try {
      await _client.from('books').update({
        'name': name,
        'author': author,
        'takeaways': takeaways,
        'status': status,
        'rating': rating,
        'is_favorite': isFavorite,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw AppException('Failed to update book: $e');
    }
  }

  Future<void> deleteBook(String id) async {
    try {
      await _client.from('books').delete().eq('id', id);
    } catch (e) {
      throw AppException('Failed to delete book: $e');
    }
  }

  Future<void> toggleFavorite(String id, bool currentStatus) async {
    try {
      await _client.from('books').update({'is_favorite': !currentStatus}).eq('id', id);
    } catch (e) {
      throw AppException('Failed to toggle favorite: $e');
    }
  }
}
