import 'package:equatable/equatable.dart';
import 'package:chronicle/features/search/domain/search_module.dart';

/// Inclusive calendar-day range (time of day ignored).
class SearchDateRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const SearchDateRange(this.start, this.end);

  @override
  List<Object?> get props => [start, end];
}

/// Everything the user asked for: text plus filters.
class SearchRequest extends Equatable {
  /// Minimum text length that triggers a search on its own.
  static const minQueryLength = 2;

  final String query;

  /// Modules to search; empty = all.
  final Set<SearchModule> modules;
  final SearchDateRange? dateRange;

  /// Selected tags; an item matches if it has ANY of them (OR).
  final Set<String> tags;

  /// Expense category id; only narrows Expenses.
  final String? categoryId;

  const SearchRequest({
    this.query = '',
    this.modules = const {},
    this.dateRange,
    this.tags = const {},
    this.categoryId,
  });

  String get trimmedQuery => query.trim();

  bool get hasFilters => modules.isNotEmpty || dateRange != null || tags.isNotEmpty || categoryId != null;

  int get filterCount =>
      (modules.isNotEmpty ? 1 : 0) + (dateRange != null ? 1 : 0) + (tags.isNotEmpty ? 1 : 0) + (categoryId != null ? 1 : 0);

  SearchRequest copyWith({
    String? query,
    Set<SearchModule>? modules,
    SearchDateRange? dateRange,
    bool clearDateRange = false,
    Set<String>? tags,
    String? categoryId,
    bool clearCategory = false,
  }) =>
      SearchRequest(
        query: query ?? this.query,
        modules: modules ?? this.modules,
        dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
        tags: tags ?? this.tags,
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      );

  SearchRequest clearFilters() => SearchRequest(query: query);

  @override
  List<Object?> get props => [query, modules, dateRange, tags, categoryId];
}

/// One matching item.
class SearchResult extends Equatable {
  final SearchModule module;
  final String id;
  final String title;
  final String? subtitle;
  final DateTime? date;
  final List<String> tags;
  final double? amount;

  /// The raw row, for screens that need the full model to open.
  final Map<String, dynamic> row;

  const SearchResult({
    required this.module,
    required this.id,
    required this.title,
    this.subtitle,
    this.date,
    this.tags = const [],
    this.amount,
    this.row = const {},
  });

  @override
  List<Object?> get props => [module, id, title, subtitle, date, tags, amount];
}

/// Results (or the failure) for one module.
class SearchModuleResult extends Equatable {
  final SearchModule module;
  final List<SearchResult> items;

  /// Set when this module's query failed; the others still show.
  final String? error;

  const SearchModuleResult({required this.module, this.items = const [], this.error});

  bool get failed => error != null;

  @override
  List<Object?> get props => [module, items, error];
}

/// An expense category for the category filter.
class SearchCategory extends Equatable {
  final String id;
  final String name;

  const SearchCategory({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
