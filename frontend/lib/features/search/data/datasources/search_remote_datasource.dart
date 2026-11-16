import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/features/search/domain/search_module.dart';
import 'package:chronicle/features/search/domain/search_query_builder.dart';

/// Supabase queries for the global search.
class SearchRemoteDatasource {
  final SupabaseClient _client;

  SearchRemoteDatasource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Rows for one module, newest first, at most [SearchQueryBuilder.perModuleLimit].
  Future<List<Map<String, dynamic>>> fetch(SearchPlan plan) async {
    final spec = plan.module.spec;
    var query = _client.from(spec.table).select(spec.select).eq('user_id', _userId);
    if (spec.softDelete) query = query.filter('deleted_at', 'is', null);
    for (final e in spec.equals.entries) {
      query = query.eq(e.key, e.value);
    }
    if (plan.textFilter != null) query = query.or(plan.textFilter!);
    if (plan.dateFrom != null) query = query.gte(spec.dateColumn, plan.dateFrom!);
    if (plan.dateBefore != null) query = query.lt(spec.dateColumn, plan.dateBefore!);
    if (plan.tagsOverlap != null) query = query.filter('tags', 'ov', plan.tagsOverlap!);
    if (plan.categoryId != null) query = query.eq('category_id', plan.categoryId!);

    final rows = await query.order(spec.dateColumn, ascending: false).limit(SearchQueryBuilder.perModuleLimit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// The `tags` value of every row in [module].
  Future<List<Object?>> fetchTags(SearchModule module) async {
    var query = _client.from(module.spec.table).select('tags').eq('user_id', _userId);
    if (module.spec.softDelete) query = query.filter('deleted_at', 'is', null);
    final rows = await query;
    return [for (final r in rows) r['tags']];
  }

  Future<List<Map<String, dynamic>>> fetchExpenseCategories() async {
    final rows = await _client.from('categories').select('id,name').eq('type', 'expense').order('name');
    return List<Map<String, dynamic>>.from(rows);
  }
}
