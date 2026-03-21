import 'package:chronicle/features/books/domain/models/book.dart';

abstract class BookRepository {
  Future<List<Book>> getBooks();
  Future<void> createBook({
    required String name,
    String? author,
    String? takeaways,
    String status,
    double? rating,
    bool isFavorite,
  });
  Future<void> updateBook({
    required String id,
    required String name,
    String? author,
    String? takeaways,
    required String status,
    double? rating,
    required bool isFavorite,
  });
  Future<void> deleteBook(String id);
  Future<void> toggleFavorite(String id, bool currentStatus);
}
