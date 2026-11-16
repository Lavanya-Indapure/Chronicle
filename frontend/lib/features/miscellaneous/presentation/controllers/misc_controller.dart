import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/core/providers/supabase_provider.dart';
import 'package:chronicle/features/miscellaneous/data/datasources/misc_remote_datasource.dart';
import 'package:chronicle/features/miscellaneous/data/repositories/misc_repository_impl.dart';
import 'package:chronicle/features/miscellaneous/domain/models/misc_item.dart';
import 'package:chronicle/features/miscellaneous/domain/repositories/misc_repository.dart';

// ── State ──
class MiscState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<MiscItem> items;
  final String searchQuery;

  const MiscState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.searchQuery = '',
  });

  /// [errorMessage] is cleared on every copy unless passed again.
  MiscState copyWith({bool? isLoading, String? errorMessage, List<MiscItem>? items, String? searchQuery}) {
    return MiscState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Items whose title or note contains the search text.
  List<MiscItem> get filteredItems {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where((i) =>
            (i.title?.toLowerCase().contains(query) ?? false) || (i.content?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, items, searchQuery];
}

// ── DI ──
final miscRepositoryProvider = Provider<MiscRepository>((ref) {
  return MiscRepositoryImpl(MiscRemoteDatasource(ref.watch(supabaseClientProvider)));
});

final miscControllerProvider = NotifierProvider<MiscController, MiscState>(MiscController.new);

// ── Controller ──
class MiscController extends Notifier<MiscState> {
  MiscRepository get _repository => ref.read(miscRepositoryProvider);

  @override
  MiscState build() {
    Future.microtask(loadItems);
    return const MiscState(isLoading: true);
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.getItems();
      state = state.copyWith(isLoading: false, items: items);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Creates a new item, or updates [existing]. Returns true on success; on
  /// failure sets [MiscState.errorMessage].
  Future<bool> saveItem({
    MiscItem? existing,
    String? title,
    String? content,
    File? newImage,
    bool removeImage = false,
  }) async {
    try {
      if (existing == null) {
        await _repository.createItem(title: title, content: content, image: newImage);
      } else {
        await _repository.updateItem(
          existing,
          title: title,
          content: content,
          newImage: newImage,
          removeImage: removeImage,
        );
      }
      await loadItems();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  /// Removes the item from the list immediately; restores it if the delete
  /// fails.
  Future<bool> deleteItem(String id) async {
    final previous = state.items;
    state = state.copyWith(items: previous.where((i) => i.id != id).toList());
    try {
      await _repository.deleteItem(id);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(items: previous, errorMessage: e.message);
      return false;
    }
  }

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
}
