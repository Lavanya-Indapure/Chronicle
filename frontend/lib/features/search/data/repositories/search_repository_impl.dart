import 'package:chronicle/core/errors/error_handler.dart';
import 'package:chronicle/core/services/logger_service.dart';
import 'package:chronicle/core/utils/tags.dart';
import 'package:chronicle/features/search/data/datasources/search_remote_datasource.dart';
import 'package:chronicle/features/search/domain/repositories/search_repository.dart';
import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/domain/search_module.dart';
import 'package:chronicle/features/search/domain/search_query_builder.dart';
import 'package:chronicle/features/search/domain/search_result_mapper.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDatasource _datasource;

  SearchRepositoryImpl(this._datasource);

  @override
  Future<List<SearchModuleResult>> search(List<SearchPlan> plans) {
    return Future.wait([
      for (final plan in plans)
        _datasource.fetch(plan).then(
              (rows) => SearchModuleResult(
                module: plan.module,
                items: [for (final r in rows) SearchResultMapper.map(plan.module, r)],
              ),
              onError: (Object e, StackTrace st) {
                LoggerService.error('Search failed in ${plan.module.name}', error: e, stackTrace: st, tag: 'Search');
                return SearchModuleResult(module: plan.module, error: ErrorHandler.handle(e).message);
              },
            ),
    ]);
  }

  @override
  Future<List<String>> getAllTags() async {
    final perModule = await Future.wait([
      for (final m in SearchModule.taggableModules)
        _datasource.fetchTags(m).then<List<Object?>>((v) => v, onError: (Object e, StackTrace st) {
          LoggerService.error('Tag catalogue: ${m.name} unavailable', error: e, stackTrace: st, tag: 'Search');
          return const <Object?>[];
        }),
    ]);
    final all = <String>{for (final values in perModule) for (final v in values) ...TagUtils.fromJson(v)};
    return all.toList();
  }

  @override
  Future<List<SearchCategory>> getExpenseCategories() async {
    try {
      final rows = await _datasource.fetchExpenseCategories();
      return [for (final r in rows) SearchCategory(id: '${r['id']}', name: '${r['name']}')];
    } catch (e, st) {
      LoggerService.error('Search: categories unavailable', error: e, stackTrace: st, tag: 'Search');
      return const [];
    }
  }
}
