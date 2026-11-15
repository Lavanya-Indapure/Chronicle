// Smoke tests for the redesigned More hub (+ Profile, Settings, placeholders),
// Books and Movies screens: fake data, both themes, small and large phones.
// Harness + snapshot instructions: test/helpers/ui_test_harness.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/theme_controller.dart';
import 'package:chronicle/features/books/domain/models/book.dart';
import 'package:chronicle/features/books/presentation/controllers/book_controller.dart';
import 'package:chronicle/features/books/presentation/screens/books_screen.dart';
import 'package:chronicle/features/more/presentation/controllers/user_profile_provider.dart';
import 'package:chronicle/features/more/presentation/screens/account_screens.dart';
import 'package:chronicle/features/more/presentation/screens/more_screen.dart';
import 'package:chronicle/features/more/presentation/screens/more_sub_screens.dart';
import 'package:chronicle/features/movies/domain/models/movie.dart';
import 'package:chronicle/features/movies/presentation/controllers/movie_controller.dart';
import 'package:chronicle/features/movies/presentation/screens/movies_screen.dart';

import 'helpers/ui_test_harness.dart';

// ── Fake data ──

final _now = DateTime.now();

const _profile = UserProfile(firstName: 'Lavanya', lastName: 'Indapure', email: 'lavanya@example.com');

Book _book(String id, String name, String status, {String? author, double? rating, bool fav = false, String? takeaways}) =>
    Book(
      id: id,
      userId: 'u',
      name: name,
      author: author,
      takeaways: takeaways,
      status: status,
      rating: rating,
      isFavorite: fav,
      createdAt: _now,
      updatedAt: _now,
    );

final _sampleBooks = [
  _book('b1', 'Atomic Habits', 'completed',
      author: 'James Clear',
      rating: 5,
      fav: true,
      takeaways: 'Small habits compound. Make good habits obvious, attractive, easy and satisfying.'),
  _book('b2', 'The Psychology of Money', 'reading', author: 'Morgan Housel', rating: 4),
  _book('b3', 'Ikigai: The Japanese Secret to a Long and Happy Life', 'reading', author: 'Héctor García'),
];

Movie _movie(String id, String name, String platform, int rating, {int daysAgo = 3, double? cost, String? comments}) => Movie(
      id: id,
      userId: 'u',
      name: name,
      watchDate: _now.subtract(Duration(days: daysAgo)),
      platform: platform,
      rating: rating,
      cost: cost,
      comments: comments,
    );

final _sampleMovies = [
  _movie('m1', 'Dune: Part Two', 'theatre', 5, daysAgo: 2, cost: 450, comments: 'Stunning on the big screen.'),
  _movie('m2', 'Past Lives', 'mobile-laptop', 4, daysAgo: 10),
  _movie('m3', 'Oppenheimer', 'theatre', 4, daysAgo: 40, cost: 380),
];

List<Book> _books = [];
List<Movie> _movies = [];

class _FakeBookController extends BookController {
  @override
  BookState build() => BookState(books: _books);

  @override
  Future<void> loadBooks() async {}
}

class _FakeMovieController extends MovieController {
  @override
  MovieState build() => MovieState(movies: _movies);

  @override
  Future<void> loadMovies() async {}
}

void main() {
  final themes = setUpUiTests();
  const sizes = {'360': smallPhone, '412': largePhone};

  tearDown(() {
    _books = [];
    _movies = [];
  });

  Future<void> pump(WidgetTester tester, Widget screen, {required ThemeData theme, Size size = smallPhone}) =>
      pumpAppScreen(
        tester,
        screen: screen,
        theme: theme,
        size: size,
        overrides: [
          userProfileProvider.overrideWithValue(_profile),
          bookControllerProvider.overrideWith(_FakeBookController.new),
          movieControllerProvider.overrideWith(_FakeMovieController.new),
        ],
      );

  for (final MapEntry(key: themeName, value: theme) in themes.all.entries) {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      testWidgets('More hub renders ($themeName, ${sizeName}dp)', (tester) async {
        await pump(tester, const MoreScreen(), theme: theme, size: Size(size.width, 1400));
        expect(tester.takeException(), isNull);
        expect(find.text('Lavanya Indapure'), findsOneWidget);
        expect(find.text(AppStrings.firstTimeLabel), findsOneWidget);
        expect(find.text(AppStrings.logOut), findsOneWidget);
        if (sizeName == '412') await captureSnapshot(tester, 'more_hub_$themeName');
      });

      testWidgets('Books with data ($themeName, ${sizeName}dp)', (tester) async {
        _books = _sampleBooks;
        await pump(tester, const BooksScreen(), theme: theme, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('Atomic Habits'), findsOneWidget);
        expect(find.text('${AppStrings.bookStatusReading} 2'), findsOneWidget);
        if (sizeName == '412') await captureSnapshot(tester, 'books_$themeName');
      });

      testWidgets('Movies with data ($themeName, ${sizeName}dp)', (tester) async {
        _movies = _sampleMovies;
        await pump(tester, const MoviesScreen(), theme: theme, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('Dune: Part Two'), findsOneWidget);
        expect(find.text('${AppStrings.platformTheatre} 2'), findsOneWidget);
        if (sizeName == '412') await captureSnapshot(tester, 'movies_$themeName');
      });
    }

    testWidgets('Profile and Settings render ($themeName)', (tester) async {
      await pump(tester, const ProfileScreen(), theme: theme);
      expect(tester.takeException(), isNull);
      expect(find.text('lavanya@example.com'), findsWidgets);
      await captureSnapshot(tester, 'profile_$themeName');

      await pump(tester, const SettingsScreen(), theme: theme);
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.themeSystem), findsOneWidget);
      await captureSnapshot(tester, 'settings_$themeName');
    });

    testWidgets('Empty Books and Movies show a call to action ($themeName)', (tester) async {
      await pump(tester, const BooksScreen(), theme: theme);
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.libraryEmptyTitle), findsOneWidget);
      await captureSnapshot(tester, 'books_empty_$themeName');

      await pump(tester, const MoviesScreen(), theme: theme);
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.moviesEmptyTitle), findsOneWidget);
    });
  }

  testWidgets('Settings theme switch updates the theme mode', (tester) async {
    await pump(tester, const SettingsScreen(), theme: themes.dark);
    await tester.tap(find.text(AppStrings.themeLight));
    await tester.pumpAndSettle();
    final container = ProviderScopeFinder.container(tester);
    expect(container.read(themeControllerProvider), ThemeMode.light);
  });

  testWidgets('Placeholder screens render', (tester) async {
    await pump(tester, const LifeLessonsScreen(), theme: themes.dark);
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.comingSoon), findsOneWidget);
    await pump(tester, const MiscellaneousScreen(), theme: themes.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Books: search with no matches shows a muted notice; tapping a book opens the edit sheet', (tester) async {
    _books = _sampleBooks;
    await pump(tester, const BooksScreen(), theme: themes.dark, size: largePhone);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.libraryNoMatchesTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Psychology of Money'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.editBook), findsOneWidget);
    expect(find.byTooltip(AppStrings.delete), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureSnapshot(tester, 'book_edit_sheet_dark');
  });

  testWidgets('Movies: platform filter, and Theatre shows the ticket cost field', (tester) async {
    _movies = _sampleMovies;
    await pump(tester, const MoviesScreen(), theme: themes.dark, size: largePhone);
    await tester.tap(find.text('${AppStrings.platformDigital} 1'));
    await tester.pumpAndSettle();
    expect(find.text('Past Lives'), findsOneWidget);
    expect(find.text('Dune: Part Two'), findsNothing);

    await tester.tap(find.text(AppStrings.logMovie));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.ticketCost), findsNothing);
    await tester.tap(find.text(AppStrings.platformTheatre).last);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.ticketCost), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureSnapshot(tester, 'movie_add_sheet_dark');
  });
}

/// Reads the app's ProviderContainer from the widget tree.
abstract final class ProviderScopeFinder {
  static ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
}
