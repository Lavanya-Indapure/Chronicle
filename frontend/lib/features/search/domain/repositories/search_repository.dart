import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/domain/search_query_builder.dart';

abstract class SearchRepository {
  /// Runs every plan in parallel. A failing module comes back with
  /// [SearchModuleResult.error] set instead of failing the whole search.
  Future<List<SearchModuleResult>> search(List<SearchPlan> plans);

  /// Every tag stored in any taggable module (all spellings). Modules that
  /// can't be read (e.g. migration not run yet) are skipped.
  Future<List<String>> getAllTags();

  Future<List<SearchCategory>> getExpenseCategories();
}
