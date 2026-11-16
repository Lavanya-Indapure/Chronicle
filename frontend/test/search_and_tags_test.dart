// Global search + tags: pure query building / escaping / mapping, the
// search controller's debounce and stale-response handling, the search
// screen (light/dark, 360dp, partial and total failure), and tags on books
// and movies.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/tags.dart';
import 'package:chronicle/features/books/domain/models/book.dart';
import 'package:chronicle/features/books/presentation/controllers/book_controller.dart';
import 'package:chronicle/features/books/presentation/screens/books_screen.dart';
import 'package:chronicle/features/movies/domain/models/movie.dart';
import 'package:chronicle/features/search/domain/repositories/search_repository.dart';
import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/domain/search_module.dart';
import 'package:chronicle/features/search/domain/search_query_builder.dart';
import 'package:chronicle/features/search/domain/search_result_mapper.dart';
import 'package:chronicle/features/search/presentation/controllers/search_controller.dart';
import 'package:chronicle/features/search/presentation/screens/search_screen.dart';
import 'package:chronicle/features/search/presentation/widgets/highlighted_text.dart';
import 'package:chronicle/features/thoughts/domain/models/thought.dart';
import 'helpers/ui_test_harness.dart';

// ── Fakes ──

/// Answers each search with [respond]; records every call.
class _FakeSearchRepository implements SearchRepository {
  final List<List<SearchPlan>> calls = [];
  Future<List<SearchModuleResult>> Function(List<SearchPlan> plans) respond;
  List<String> tags;

  _FakeSearchRepository({required this.respond, this.tags = const []});

  @override
  Future<List<SearchModuleResult>> search(List<SearchPlan> plans) {
    calls.add(plans);
    return respond(plans);
  }

  @override
  Future<List<String>> getAllTags() async => tags;

  @override
  Future<List<SearchCategory>> getExpenseCategories() async => const [SearchCategory(id: 'c1', name: 'Food')];
}

SearchResult _hit(SearchModule m, String id, String title, {String? subtitle, List<String> tags = const []}) =>
    SearchResult(module: m, id: id, title: title, subtitle: subtitle, date: DateTime(2026, 11, 10), tags: tags);

/// Every planned module gets [items]; modules in [failing] fail.
Future<List<SearchModuleResult>> Function(List<SearchPlan>) _answer(
  Map<SearchModule, List<SearchResult>> items, {
  Set<SearchModule> failing = const {},
}) =>
    (plans) async => [
          for (final p in plans)
            failing.contains(p.module)
                ? SearchModuleResult(module: p.module, error: 'column "tags" does not exist')
                : SearchModuleResult(module: p.module, items: items[p.module] ?? const []),
        ];

void main() {
  final themes = setUpUiTests();

  group('Tags', () {
    test('parse trims, drops blanks and "#", de-duplicates case-insensitively', () {
      expect(TagUtils.parse(' growth, #Patience ,, growth,GROWTH '), ['growth', 'Patience']);
      expect(TagUtils.parse('   '), isEmpty);
    });

    test('fromJson reads text[] and both legacy text forms', () {
      expect(TagUtils.fromJson(['a', 'b']), ['a', 'b']);
      expect(TagUtils.fromJson('motivation, life'), ['motivation', 'life']);
      expect(TagUtils.fromJson('["x","y"]'), ['x', 'y']);
      expect(TagUtils.fromJson(null), isEmpty);
    });

    test('forWrite omits the column only for untagged rows that stay untagged', () {
      expect(TagUtils.forWrite(const []), isNull);
      expect(TagUtils.forWrite(const ['a']), ['a']);
      expect(TagUtils.forWrite(const [], previous: const ['a']), isEmpty); // clearing is written
    });

    test('collect and has ignore case', () {
      expect(TagUtils.collect([const ['b', 'A'], const ['a', 'c']]), ['A', 'b', 'c']);
      expect(TagUtils.has(const ['Career'], 'career'), isTrue);
      expect(TagUtils.has(const ['Career'], null), isTrue);
      expect(TagUtils.has(const [], 'x'), isFalse);
    });

    test('thoughts read legacy comma tags', () {
      final t = Thought.fromJson({
        'id': 't',
        'user_id': 'u',
        'content': 'c',
        'tags': 'life, focus',
        'created_at': '2026-11-01T00:00:00Z',
        'updated_at': '2026-11-01T00:00:00Z',
      });
      expect(t.tags, ['life', 'focus']);
    });
  });

  group('SearchQueryBuilder', () {
    test('escapes LIKE wildcards and PostgREST reserved characters', () {
      expect(SearchQueryBuilder.likePattern('50%_off*'), r'%50\%\_off%');
      expect(SearchQueryBuilder.quoteFilterValue(r'a"b\c'), r'"a\"b\\c"');
      expect(
        SearchQueryBuilder.orIlike(['title', 'description'], 'tea, cake (2%)'),
        r'title.ilike."%tea, cake (2\\%)%",description.ilike."%tea, cake (2\\%)%"',
      );
      expect(SearchQueryBuilder.arrayLiteral(['a', 'b "c"']), r'{"a","b \"c\""}');
    });

    test('searches with 2+ letters, or with only a tag / date filter', () {
      expect(SearchQueryBuilder.shouldSearch(const SearchRequest(query: ' a ')), isFalse);
      expect(SearchQueryBuilder.shouldSearch(const SearchRequest(query: 'ab')), isTrue);
      expect(SearchQueryBuilder.shouldSearch(const SearchRequest(tags: {'x'})), isTrue);
      expect(
        SearchQueryBuilder.shouldSearch(SearchRequest(dateRange: SearchDateRange(DateTime(2026), DateTime(2026, 2)))),
        isTrue,
      );
      expect(SearchQueryBuilder.build(const SearchRequest(query: 'a')), isEmpty);
    });

    test('all modules by default; selected only; tags limit to taggable modules', () {
      expect(SearchQueryBuilder.modulesFor(const SearchRequest(query: 'ab')), SearchModule.values);
      expect(
        SearchQueryBuilder.modulesFor(const SearchRequest(query: 'ab', modules: {SearchModule.books, SearchModule.expenses})),
        [SearchModule.expenses, SearchModule.books],
      );
      expect(SearchQueryBuilder.modulesFor(const SearchRequest(tags: {'x'})), SearchModule.taggableModules);
      expect(
        SearchQueryBuilder.modulesFor(const SearchRequest(tags: {'x'}, modules: {SearchModule.expenses, SearchModule.movies})),
        [SearchModule.movies],
      );
    });

    test('plans carry text, date range (end exclusive), tags (all spellings) and category', () {
      final plans = SearchQueryBuilder.build(
        SearchRequest(
          query: 'run',
          tags: const {'Career'},
          dateRange: SearchDateRange(DateTime(2026, 11, 1, 18), DateTime(2026, 11, 30, 9)),
          categoryId: 'c1',
          modules: const {SearchModule.books, SearchModule.expenses},
        ),
        tagSpellings: SearchQueryBuilder.spellingsOf(['career', 'Career', 'other']),
      );
      // Tags selected → expenses (not taggable) is dropped.
      expect(plans.map((p) => p.module), [SearchModule.books]);
      final books = plans.single;
      expect(books.textFilter, startsWith('name.ilike."%run%"'));
      expect(books.dateFrom, '2026-11-01');
      expect(books.dateBefore, '2026-12-01');
      expect(books.tagsOverlap, '{"Career","career"}');
      expect(books.categoryId, isNull);

      final expenses = SearchQueryBuilder.build(const SearchRequest(query: 'run', categoryId: 'c1'))
          .firstWhere((p) => p.module == SearchModule.expenses);
      expect(expenses.categoryId, 'c1');
      expect(expenses.tagsOverlap, isNull);
    });
  });

  group('SearchResultMapper', () {
    test('expenses show category and amount; moods get emoji labels', () {
      final e = SearchResultMapper.map(SearchModule.expenses, {
        'id': 'e1',
        'description': 'Groceries',
        'amount': 450,
        'expense_date': '2026-11-10',
        'categories': {'name': 'Food'},
      });
      expect((e.title, e.subtitle, e.amount, e.date), ('Groceries', 'Food', 450.0, DateTime(2026, 11, 10)));

      final m = SearchResultMapper.map(SearchModule.moods, {'id': 'm', 'mood': 'happy', 'note': 'Sunny', 'log_date': '2026-11-02'});
      expect(m.title, '😊 Happy');
      expect(m.subtitle, 'Sunny');
    });

    test('untitled lessons and photo-only misc items get sensible titles', () {
      final l = SearchResultMapper.map(SearchModule.lifeLessons, {'id': 'l', 'content': 'Rest', 'tags': ['health']});
      expect((l.title, l.subtitle), ('Rest', null));
      expect(l.tags, ['health']);
      final misc = SearchResultMapper.map(SearchModule.misc, {'id': 'x', 'storage_path': 'u/p.jpg'});
      expect(misc.title, AppStrings.searchPhotoOnly);
      final t = SearchResultMapper.map(SearchModule.thoughts, {'id': 't', 'content': 'Hi', 'tags': 'a, b'});
      expect(t.tags, ['a', 'b']);
    });

    test('highlight finds the match case-insensitively', () {
      expect(HighlightedText.matchIndex('Atomic Habits', 'habit'), 7);
      expect(HighlightedText.matchIndex('Atomic Habits', 'zz'), -1);
      expect(HighlightedText.matchIndex('Atomic Habits', '  '), -1);
    });
  });

  group('Search controller', () {
    testWidgets('typing is debounced into one search', (tester) async {
      final repo = _FakeSearchRepository(respond: _answer({}));
      final container = ProviderContainer(overrides: [searchRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(container.dispose);
      final sub = container.listen(searchControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(searchControllerProvider.notifier);

      controller.setQuery('a');
      controller.setQuery('at');
      await tester.pump(const Duration(milliseconds: 100));
      controller.setQuery('ato');
      await tester.pump(const Duration(milliseconds: 299));
      expect(repo.calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 2));
      expect(repo.calls.length, 1);
      expect(repo.calls.single.first.textFilter, contains('%ato%'));
    });

    testWidgets('a slow earlier response never overwrites a newer one', (tester) async {
      final slow = Completer<List<SearchModuleResult>>();
      var call = 0;
      final repo = _FakeSearchRepository(respond: (plans) {
        call++;
        if (call == 1) return slow.future;
        return _answer({SearchModule.books: [_hit(SearchModule.books, 'b2', 'Newer')]})(plans);
      });
      final container = ProviderContainer(overrides: [searchRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(container.dispose);
      final sub = container.listen(searchControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(searchControllerProvider.notifier);

      controller.setQuery('old');
      await tester.pump(const Duration(milliseconds: 350));
      controller.setQuery('new');
      await tester.pump(const Duration(milliseconds: 350));
      expect(container.read(searchControllerProvider).withItems.single.items.single.title, 'Newer');

      slow.complete([SearchModuleResult(module: SearchModule.books, items: [_hit(SearchModule.books, 'b1', 'Stale')])]);
      await tester.pump();
      expect(container.read(searchControllerProvider).withItems.single.items.single.title, 'Newer');
    });
  });

  group('Search screen', () {
    final items = {
      SearchModule.books: [_hit(SearchModule.books, 'b1', 'Atomic Habits', subtitle: 'James Clear', tags: ['habits', 'growth'])],
      SearchModule.thoughts: [_hit(SearchModule.thoughts, 't1', 'Small habits compound into big results over the years', tags: ['habits'])],
      SearchModule.todos: [_hit(SearchModule.todos, 'td', 'Build a reading habit')],
    };

    Future<_FakeSearchRepository> pumpSearch(WidgetTester tester, ThemeData theme, _FakeSearchRepository repo) async {
      await pumpAppScreen(
        tester,
        screen: const SearchScreen(),
        theme: theme,
        overrides: [searchRepositoryProvider.overrideWithValue(repo)],
      );
      return repo;
    }

    Future<void> typeQuery(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
    }

    for (final MapEntry(key: themeName, value: theme) in themes.all.entries) {
      testWidgets('idle, results and partial failure render ($themeName, 360dp)', (tester) async {
        final repo = await pumpSearch(
          tester,
          theme,
          _FakeSearchRepository(respond: _answer(items, failing: {SearchModule.movies}), tags: ['habits', 'Habits']),
        );
        expect(find.text(AppStrings.searchStartTitle), findsOneWidget);

        await typeQuery(tester, 'habit');
        expect(tester.takeException(), isNull);
        expect(repo.calls, hasLength(1));
        expect(find.text(AppStrings.searchModuleBooks), findsOneWidget);
        expect(find.text(AppStrings.searchModuleThoughts), findsOneWidget);
        expect(find.textContaining('${AppStrings.searchPartialFailure} ${AppStrings.searchModuleMovies}'), findsOneWidget);
        expect(find.text('#habits'), findsWidgets);
        if (themeName == 'light') await captureSnapshot(tester, 'search_results_light');
      });
    }

    testWidgets('no matches, and everything failing, show their states', (tester) async {
      final repo = _FakeSearchRepository(respond: _answer({}));
      await pumpSearch(tester, themes.light, repo);
      await typeQuery(tester, 'zzz');
      expect(find.text(AppStrings.searchNoMatchesTitle), findsOneWidget);

      repo.respond = _answer({}, failing: SearchModule.values.toSet());
      await typeQuery(tester, 'zzzz');
      expect(find.text(AppStrings.searchErrorTitle), findsOneWidget);
      expect(find.text(AppStrings.searchRetry), findsOneWidget);
    });

    testWidgets('picking a tag in the filters searches tagged modules only', (tester) async {
      final repo = _FakeSearchRepository(respond: _answer(items), tags: ['habits', 'Habits']);
      await pumpSearch(tester, themes.dark, repo);
      await tester.tap(find.text(AppStrings.searchFilters));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final chip = find.widgetWithText(FilterChip, '#habits');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pump();
      final plans = repo.calls.last;
      expect(plans.map((p) => p.module).toSet(), SearchModule.taggableModules.toSet());
      expect(plans.first.tagsOverlap, '{"Habits","habits"}');
    });
  });

  group('Book and movie tags', () {
    Book book(String id, String name, List<String> tags) => Book(
          id: id,
          userId: 'u',
          name: name,
          status: 'reading',
          isFavorite: false,
          tags: tags,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

    test('book list filters by tag and searches tags', () {
      final state = BookState(books: [book('1', 'Atomic Habits', ['Habits']), book('2', 'Dune', ['scifi'])]);
      expect(state.allTags, ['Habits', 'scifi']);
      expect(state.copyWith(selectedTag: 'habits').filteredBooks.map((b) => b.name), ['Atomic Habits']);
      expect(state.copyWith(searchQuery: 'sci').filteredBooks.map((b) => b.name), ['Dune']);
    });

    test('movie writes omit tags only for untagged movies that stay untagged', () {
      Movie movie(List<String> tags) =>
          Movie(id: 'm', userId: 'u', name: 'Dune', watchDate: DateTime(2026), platform: 'theatre', rating: 5, tags: tags);
      expect(movie(const []).toJson().containsKey('tags'), isFalse);
      expect(movie(const ['scifi']).toJson()['tags'], ['scifi']);
      expect(movie(const []).toJson(previousTags: const ['scifi'])['tags'], isEmpty);
    });

    testWidgets('books screen shows tag pills and a working tag filter', (tester) async {
      final books = [book('1', 'Atomic Habits', ['habits']), book('2', 'Dune', ['scifi'])];
      await pumpAppScreen(
        tester,
        screen: const BooksScreen(),
        theme: themes.light,
        overrides: [bookControllerProvider.overrideWith(() => _FakeBookController(books))],
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Dune'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '#habits'));
      await tester.pump();
      expect(find.text('Dune'), findsNothing);
      expect(find.text('Atomic Habits'), findsOneWidget);
    });
  });
}

class _FakeBookController extends BookController {
  final List<Book> books;

  _FakeBookController(this.books);

  @override
  BookState build() => BookState(books: books);

  @override
  Future<void> loadBooks() async {}
}
