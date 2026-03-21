import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:chronicle/features/books/domain/models/book.dart';
import 'package:chronicle/features/books/domain/repositories/book_repository.dart';
import 'package:chronicle/features/books/data/repositories/book_repository_impl.dart';
import 'package:chronicle/features/books/data/datasources/book_remote_datasource.dart';
import 'package:chronicle/core/errors/app_exception.dart';

class BookState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Book> books;
  final String searchQuery;
  final String? statusFilter; // 'reading', 'completed', null
  final bool onlyFavorites;

  const BookState({
    this.isLoading = false,
    this.errorMessage,
    this.books = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.onlyFavorites = false,
  });

  BookState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Book>? books,
    String? searchQuery,
    String? statusFilter,
    bool? onlyFavorites,
    bool clearStatus = false,
  }) {
    return BookState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      books: books ?? this.books,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
    );
  }

  List<Book> get filteredBooks {
    return books.where((b) {
      if (onlyFavorites && !b.isFavorite) return false;
      if (statusFilter != null && b.status != statusFilter) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = b.name.toLowerCase().contains(query);
        final matchesAuthor = b.author?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesAuthor) return false;
      }
      return true;
    }).toList();
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, books, searchQuery, statusFilter, onlyFavorites];
}

class BookController extends Notifier<BookState> {
  late final BookRepository _repository;

  @override
  BookState build() {
    final client = Supabase.instance.client;
    final datasource = BookRemoteDatasource(client);
    _repository = BookRepositoryImpl(datasource);
    
    Future.microtask(() => loadBooks());
    
    return const BookState();
  }

  Future<void> loadBooks() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final books = await _repository.getBooks();
      state = state.copyWith(books: books, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
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
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createBook(
        name: name,
        author: author,
        takeaways: takeaways,
        status: status,
        rating: rating,
        isFavorite: isFavorite,
      );
      await loadBooks();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
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
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateBook(
        id: id,
        name: name,
        author: author,
        takeaways: takeaways,
        status: status,
        rating: rating,
        isFavorite: isFavorite,
      );
      await loadBooks();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> deleteBook(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteBook(id);
      await loadBooks();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> toggleFavorite(Book book) async {
    try {
      await _repository.toggleFavorite(book.id, book.isFavorite);
      await loadBooks();
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void toggleOnlyFavorites() => state = state.copyWith(onlyFavorites: !state.onlyFavorites);
  void setStatusFilter(String? status) => state = state.copyWith(statusFilter: status, clearStatus: status == null);
}

final bookControllerProvider = NotifierProvider<BookController, BookState>(BookController.new);
