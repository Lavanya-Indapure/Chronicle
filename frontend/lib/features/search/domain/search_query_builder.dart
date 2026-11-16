import 'package:equatable/equatable.dart';
import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/domain/search_module.dart';

/// Everything one module's query needs, as PostgREST filter values.
/// Pure data, so the query building is unit-testable without Supabase.
class SearchPlan extends Equatable {
  final SearchModule module;

  /// Value for `.or(...)`: text columns `ilike` the query; null = no text filter.
  final String? textFilter;

  /// `dateColumn >= dateFrom` (yyyy-MM-dd).
  final String? dateFrom;

  /// `dateColumn < dateBefore` (yyyy-MM-dd, the day after the range end) —
  /// works for both `date` and timestamp columns.
  final String? dateBefore;

  /// Value for the `ov` (array overlaps) filter on `tags`, e.g. `{"a","b"}`.
  final String? tagsOverlap;

  /// Expenses only: `category_id = categoryId`.
  final String? categoryId;

  const SearchPlan({
    required this.module,
    this.textFilter,
    this.dateFrom,
    this.dateBefore,
    this.tagsOverlap,
    this.categoryId,
  });

  @override
  List<Object?> get props => [module, textFilter, dateFrom, dateBefore, tagsOverlap, categoryId];
}

abstract final class SearchQueryBuilder {
  /// Rows fetched per module.
  static const perModuleLimit = 20;

  /// Whether [r] asks for anything: enough text, or a tag / date filter.
  static bool shouldSearch(SearchRequest r) =>
      r.trimmedQuery.length >= SearchRequest.minQueryLength || r.tags.isNotEmpty || r.dateRange != null;

  /// Modules to query: the selected ones (all when none selected); with
  /// tags selected, only taggable modules — the others can't match a tag.
  static List<SearchModule> modulesFor(SearchRequest r) {
    final selected = r.modules.isEmpty ? SearchModule.values : SearchModule.values.where(r.modules.contains);
    return [for (final m in selected) if (r.tags.isEmpty || m.taggable) m];
  }

  /// One plan per module to query; empty when [shouldSearch] is false.
  ///
  /// [tagSpellings] maps a lower-cased tag to every spelling stored (e.g.
  /// `career` → {Career, career}); array overlap is case-sensitive, so all
  /// spellings are sent.
  static List<SearchPlan> build(SearchRequest r, {Map<String, Set<String>> tagSpellings = const {}}) {
    if (!shouldSearch(r)) return const [];
    final q = r.trimmedQuery;
    final text = q.length >= SearchRequest.minQueryLength ? q : null;
    final range = r.dateRange;
    final tags = r.tags.isEmpty ? null : arrayLiteral(tagVariants(r.tags, tagSpellings));

    return [
      for (final m in modulesFor(r))
        SearchPlan(
          module: m,
          textFilter: text == null ? null : orIlike(m.spec.textColumns, text),
          dateFrom: range == null ? null : dateBound(m, _day(range.start)),
          dateBefore: range == null ? null : dateBound(m, _day(range.end).add(const Duration(days: 1))),
          tagsOverlap: m.taggable ? tags : null,
          categoryId: m == SearchModule.expenses ? r.categoryId : null,
        ),
    ];
  }

  /// `col1.ilike."%text%",col2.ilike."%text%"` for PostgREST `.or()`.
  static String orIlike(List<String> columns, String text) {
    final value = quoteFilterValue(likePattern(text));
    return columns.map((c) => '$c.ilike.$value').join(',');
  }

  /// `%text%` with LIKE wildcards in [text] escaped, so "50%" matches a
  /// literal percent sign. `*` is dropped: PostgREST reads it as a wildcard
  /// and offers no escape for it.
  static String likePattern(String text) {
    final escaped = text
        .replaceAll('*', '')
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    return '%$escaped%';
  }

  /// Double-quotes a value for PostgREST's filter grammar so commas, dots,
  /// parentheses and colons in it are taken literally.
  static String quoteFilterValue(String value) =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  /// Postgres array literal: `{"a","b \"c\""}`.
  static String arrayLiteral(Iterable<String> values) =>
      '{${values.map((v) => '"${v.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"').join(',')}}';

  /// Every stored spelling of each selected tag (the tag itself included),
  /// sorted for stable output.
  static List<String> tagVariants(Set<String> selected, Map<String, Set<String>> spellings) {
    final out = <String>{};
    for (final t in selected) {
      out.add(t);
      out.addAll(spellings[t.toLowerCase()] ?? const {});
    }
    return out.toList()..sort();
  }

  /// Lower-cased tag → all its stored spellings.
  static Map<String, Set<String>> spellingsOf(Iterable<String> tags) {
    final map = <String, Set<String>>{};
    for (final t in tags) {
      map.putIfAbsent(t.toLowerCase(), () => {}).add(t);
    }
    return map;
  }

  /// Lower/upper bound for [m]'s date column at local midnight of [day].
  /// `date` columns take `yyyy-MM-dd`; timestamp columns (`*_at`) take the
  /// exact instant, so "16 Nov" means 16 Nov in the user's time zone rather
  /// than UTC (otherwise anything logged 00:00–05:30 IST lands on the day
  /// before).
  static String dateBound(SearchModule m, DateTime day) =>
      m.spec.dateColumn.endsWith('_at') ? day.toUtc().toIso8601String() : dateString(day);

  static String dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
