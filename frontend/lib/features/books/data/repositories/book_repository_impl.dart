import 'package:chronicle/features/books/domain/models/book.dart';
import 'package:chronicle/features/books/domain/repositories/book_repository.dart';
import 'package:chronicle/features/books/data/datasources/book_remote_datasource.dart';

class BookRepositoryImpl implements BookRepository {
  final BookRemoteDatasource _datasource;

  BookRepositoryImpl(this._datasource);

  @override
  Future<List<Book>> getBooks() => _datasource.getBooks();

  @override
  Future<void> createBook({
    required String name,
    String? author,
    String? takeaways,
    String status = 'reading',
    double? rating,
    bool isFavorite = false,
    List<String>? tags,
  }) => _datasource.createBook(
        name: name,
        author: author,
        takeaways: takeaways,
        status: status,
        rating: rating,
        isFavorite: isFavorite,
        tags: tags,
      );

  @override
  Future<void> updateBook({
    required String id,
    required String name,
    String? author,
    String? takeaways,
    required String status,
    double? rating,
    required bool isFavorite,
    List<String>? tags,
  }) => _datasource.updateBook(
        id: id,
        name: name,
        author: author,
        takeaways: takeaways,
        status: status,
        rating: rating,
        isFavorite: isFavorite,
        tags: tags,
      );

  @override
  Future<void> deleteBook(String id) => _datasource.deleteBook(id);

  @override
  Future<void> toggleFavorite(String id, bool currentStatus) => _datasource.toggleFavorite(id, currentStatus);
}
