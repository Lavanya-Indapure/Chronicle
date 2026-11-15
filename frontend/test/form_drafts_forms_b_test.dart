// Form drafts for the Movie, Restaurant, Restaurant visit, Photo and Thought
// sheets: input survives an accidental dismiss (tap outside), is restored
// when the same form reopens, and is cleared by a successful save.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/services/form_draft_store.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/features/movies/domain/models/movie.dart';
import 'package:chronicle/features/movies/presentation/controllers/movie_controller.dart';
import 'package:chronicle/features/movies/presentation/widgets/add_movie_sheet.dart';
import 'package:chronicle/features/movies/presentation/widgets/movie_platform.dart';
import 'package:chronicle/features/photos/presentation/controllers/photo_controller.dart';
import 'package:chronicle/features/photos/presentation/widgets/add_photo_sheet.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';
import 'package:chronicle/features/restaurants/presentation/widgets/add_restaurant_sheet.dart';
import 'package:chronicle/features/restaurants/presentation/widgets/revisit_sheet.dart';
import 'package:chronicle/features/thoughts/domain/models/thought.dart';
import 'package:chronicle/features/thoughts/presentation/controllers/thought_controller.dart';
import 'package:chronicle/features/thoughts/presentation/widgets/add_thought_sheet.dart';

import 'helpers/ui_test_harness.dart';

// ── Fakes: record saves; succeed or fail on demand ──

bool _saveOk = true;
final List<String> _saves = [];

class _FakeMovieController extends MovieController {
  @override
  MovieState build() => const MovieState();

  @override
  Future<void> loadMovies() async {}

  @override
  Future<bool> createMovie(Movie movie) async {
    _saves.add('movie:create:${movie.name}:${movie.platform}:${movie.rating}:${movie.cost}');
    return _saveOk;
  }

  @override
  Future<bool> updateMovie(String id, Movie movie) async {
    _saves.add('movie:update:$id:${movie.name}');
    return _saveOk;
  }

  @override
  Future<bool> deleteMovie(String id) async => _saveOk;
}

class _FakeRestaurantController extends RestaurantController {
  @override
  RestaurantState build() => const RestaurantState();

  @override
  Future<void> loadRestaurants() async {}

  @override
  Future<bool> createRestaurant({
    required String name,
    required String address,
    required double rating,
    double? billAmount,
    String? foodItems,
    String? notes,
    List<File> photos = const [],
    bool isFavorite = false,
  }) async {
    _saves.add('restaurant:create:$name:$isFavorite');
    return _saveOk;
  }

  @override
  Future<bool> logRevisit({
    required String restaurantId,
    required double rating,
    double? billAmount,
    String? foodItems,
    String? notes,
    List<File> photos = const [],
  }) async {
    _saves.add('restaurant:visit:$restaurantId:$billAmount');
    return _saveOk;
  }
}

class _FakePhotoController extends PhotoController {
  @override
  PhotoState build() => const PhotoState();

  @override
  Future<void> loadPhotos() async {}

  @override
  Future<bool> uploadPhoto({required File file, String? caption, required DateTime date}) async {
    _saves.add('photo:upload:$caption');
    return _saveOk;
  }
}

/// Mirrors the real controller: failures are reported via errorMessage,
/// which copyWith clears on every state change.
class _FakeThoughtController extends ThoughtController {
  @override
  ThoughtState build() => const ThoughtState();

  void _finish(String record) {
    _saves.add(record);
    state = _saveOk ? state.copyWith() : state.copyWith(errorMessage: 'Network error');
  }

  @override
  Future<void> createThought(String content, String? tags) async => _finish('thought:create:$content:$tags');

  @override
  Future<void> updateThought(String id, String content, String? tags) async => _finish('thought:update:$id:$content');

  @override
  Future<void> deleteThought(String id) async => _finish('thought:delete:$id');
}

// ── Sample data ──

final _now = DateTime.now();

final _movieA = Movie(
  id: 'm1',
  userId: 'u',
  name: 'Inception',
  watchDate: DateTime(_now.year, 1, 10),
  platform: MoviePlatform.digital,
  rating: 4,
);
final _movieB = Movie(
  id: 'm2',
  userId: 'u',
  name: 'Interstellar',
  watchDate: DateTime(_now.year, 2, 3),
  platform: MoviePlatform.theatre,
  rating: 5,
  cost: 300,
);

Restaurant _restaurant(String id, String name) => Restaurant(
      id: id,
      userId: 'u',
      name: name,
      address: 'Indiranagar',
      visitCount: 1,
      isFavorite: false,
      rating: 4,
      createdAt: _now,
      updatedAt: _now,
    );

Thought _thought(String id, String content) => Thought(
      id: id,
      userId: 'u',
      content: content,
      tags: 'life',
      isFavorite: false,
      createdAt: _now,
      updatedAt: _now,
    );

// ── Harness ──

/// Tall viewport so even the long restaurant form leaves a dimmed area above
/// the sheet to tap.
const _tallPhone = Size(412, 1800);

/// Buttons that open each given sheet as a modal bottom sheet.
class _SheetLauncher extends StatelessWidget {
  final Map<String, WidgetBuilder> sheets;

  const _SheetLauncher({required this.sheets});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final MapEntry(key: label, value: builder) in sheets.entries)
              FilledButton(
                onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: builder),
                child: Text(label),
              ),
          ],
        ),
      );
}

Future<void> _pump(WidgetTester tester, Map<String, WidgetBuilder> sheets) => pumpAppScreen(
      tester,
      screen: _SheetLauncher(sheets: sheets),
      theme: setUpThemes.dark,
      size: _tallPhone,
      overrides: [
        movieControllerProvider.overrideWith(_FakeMovieController.new),
        restaurantControllerProvider.overrideWith(_FakeRestaurantController.new),
        photoControllerProvider.overrideWith(_FakePhotoController.new),
        thoughtControllerProvider.overrideWith(_FakeThoughtController.new),
      ],
    );

Future<void> _open(WidgetTester tester, [String label = 'open']) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

/// Taps the dimmed area above the sheet — the "accidental" dismiss.
Future<void> _tapOutside(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextField, label);

String _text(WidgetTester tester, String label) => tester.widget<TextField>(_field(label)).controller!.text;

Finder get _banner => find.byType(DraftRestoredBanner);

late TestThemes setUpThemes;

void main() {
  setUpThemes = setUpUiTests();

  setUp(() {
    FormDraftStore.clearAll();
    _saveOk = true;
    _saves.clear();
  });

  // ── Movie ──
  group('Movie sheet', () {
    testWidgets('new: restores name, platform, cost and rating after tapping outside', (tester) async {
      await _pump(tester, {'open': (_) => const AddMovieSheet()});

      await _open(tester);
      expect(_banner, findsNothing);
      await tester.enterText(_field(AppStrings.movieName), 'Dune');
      await _tapVisible(tester, find.text(MoviePlatform.label(MoviePlatform.theatre)));
      await tester.enterText(_field(AppStrings.ticketCost), '450');
      await _tapVisible(tester, find.byTooltip('5'));
      await _tapOutside(tester);
      expect(find.text('Dune'), findsNothing);

      await _open(tester);
      expect(_banner, findsOneWidget);
      expect(_text(tester, AppStrings.movieName), 'Dune');
      expect(_text(tester, AppStrings.ticketCost), '450'); // only shown for Theatre
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));

      // Saving clears the draft.
      await _tapVisible(tester, find.widgetWithText(FilledButton, AppStrings.logMovie));
      expect(_saves.single, 'movie:create:Dune:${MoviePlatform.theatre}:5:450.0');
      await _open(tester);
      expect(_banner, findsNothing);
      expect(_text(tester, AppStrings.movieName), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed save keeps the draft', (tester) async {
      _saveOk = false;
      await _pump(tester, {'open': (_) => const AddMovieSheet()});
      await _open(tester);
      await tester.enterText(_field(AppStrings.movieName), 'Tenet');
      await _tapVisible(tester, find.widgetWithText(FilledButton, AppStrings.logMovie));
      await _tapOutside(tester);
      await _open(tester);
      expect(_text(tester, AppStrings.movieName), 'Tenet');
    });

    testWidgets('edit: drafts are per movie and Discard returns to the saved values', (tester) async {
      await _pump(tester, {
        'A': (_) => AddMovieSheet(movie: _movieA),
        'B': (_) => AddMovieSheet(movie: _movieB),
      });

      await _open(tester, 'A');
      await tester.enterText(_field(AppStrings.movieName), 'Inception (rewatch)');
      await _tapOutside(tester);

      await _open(tester, 'B');
      expect(_banner, findsNothing);
      expect(_text(tester, AppStrings.movieName), 'Interstellar');
      await _tapOutside(tester);

      await _open(tester, 'A');
      expect(_banner, findsOneWidget);
      expect(_text(tester, AppStrings.movieName), 'Inception (rewatch)');
      await _tapVisible(tester, find.text(AppStrings.discardDraft));
      expect(_banner, findsNothing);
      expect(_text(tester, AppStrings.movieName), 'Inception');
      expect(tester.takeException(), isNull);
    });
  });

  // ── Restaurant ──
  group('Add Restaurant sheet', () {
    testWidgets('restores text fields and the favourite toggle; save clears', (tester) async {
      await _pump(tester, {'open': (_) => const AddRestaurantSheet()});

      await _open(tester);
      await tester.enterText(_field(AppStrings.restaurantName), 'Toit');
      await tester.enterText(_field(AppStrings.address), '100 Feet Road');
      await tester.enterText(_field(AppStrings.whatYouAte), 'Pizza');
      await _tapVisible(tester, find.text(AppStrings.markAsFavourite));
      await _tapOutside(tester);

      await _open(tester);
      expect(_banner, findsOneWidget);
      expect(_text(tester, AppStrings.restaurantName), 'Toit');
      expect(_text(tester, AppStrings.address), '100 Feet Road');
      expect(_text(tester, AppStrings.whatYouAte), 'Pizza');
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);

      await _tapVisible(tester, find.widgetWithText(FilledButton, AppStrings.saveRestaurant));
      expect(_saves.single, 'restaurant:create:Toit:true');
      await _open(tester);
      expect(_banner, findsNothing);
      expect(_text(tester, AppStrings.restaurantName), isEmpty);
    });

    testWidgets('a failed save keeps the draft', (tester) async {
      _saveOk = false;
      await _pump(tester, {'open': (_) => const AddRestaurantSheet()});
      await _open(tester);
      await tester.enterText(_field(AppStrings.restaurantName), 'Truffles');
      await tester.enterText(_field(AppStrings.address), 'Koramangala');
      await _tapVisible(tester, find.widgetWithText(FilledButton, AppStrings.saveRestaurant));
      await _tapOutside(tester);
      await _open(tester);
      expect(_text(tester, AppStrings.restaurantName), 'Truffles');
    });

    testWidgets('a draft with a photo that no longer exists restores without it', (tester) async {
      FormDraftStore.write('restaurant:new', {
        'name': 'Ghost Kitchen',
        'photos': '/definitely/not/here/photo.jpg',
      });
      await _pump(tester, {'open': (_) => const AddRestaurantSheet()});
      await _open(tester);
      expect(_banner, findsOneWidget);
      expect(_text(tester, AppStrings.restaurantName), 'Ghost Kitchen');
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // ── Restaurant visit ──
  group('Log Visit sheet', () {
    testWidgets('drafts are kept per restaurant; save clears', (tester) async {
      final r1 = _restaurant('r1', 'Toit');
      final r2 = _restaurant('r2', 'Meghana');
      await _pump(tester, {
        'r1': (_) => RevisitSheet(restaurant: r1),
        'r2': (_) => RevisitSheet(restaurant: r2),
      });

      await _open(tester, 'r1');
      await tester.enterText(_field(AppStrings.billAmount), '1200');
      await tester.enterText(_field(AppStrings.visitNotes), 'Live music night');
      await _tapOutside(tester);

      await _open(tester, 'r2');
      expect(_banner, findsNothing);
      expect(_text(tester, AppStrings.billAmount), isEmpty);
      await _tapOutside(tester);

      await _open(tester, 'r1');
      expect(_banner, findsOneWidget);
      expect(_text(tester, AppStrings.billAmount), '1200');
      expect(_text(tester, AppStrings.visitNotes), 'Live music night');

      await _tapVisible(tester, find.widgetWithText(FilledButton, AppStrings.logVisit));
      expect(_saves.single, 'restaurant:visit:r1:1200.0');
      await _open(tester, 'r1');
      expect(_banner, findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // ── Photo ──
  group('Add Photo sheet', () {
    testWidgets('restores caption; a missing image file is dropped without crashing', (tester) async {
      await _pump(tester, {'open': (_) => const AddPhotoSheet()});

      await _open(tester);
      await tester.enterText(_field(AppStrings.captionOptional), 'Sunset at the beach');
      await _tapOutside(tester);

      await _open(tester);
      expect(_banner, findsOneWidget);
      expect(_text(tester, AppStrings.captionOptional), 'Sunset at the beach');
      await _tapOutside(tester);

      // Seeded draft pointing at an image that has since been deleted.
      FormDraftStore.write('photo:new', {'imagePath': '/gone/photo.jpg', 'caption': 'Lost one'});
      await _open(tester);
      expect(_text(tester, AppStrings.captionOptional), 'Lost one');
      expect(find.text(AppStrings.tapToSelectImage), findsOneWidget); // no image restored
      expect(tester.takeException(), isNull);
    });

    testWidgets('restores a picked image that still exists; upload clears the draft', (tester) async {
      final dir = Directory.systemTemp.createTempSync('draft_photo_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final image = File('${dir.path}/pixel.png')
        ..writeAsBytesSync(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
        ));
      FormDraftStore.write('photo:new', {'imagePath': image.path, 'caption': 'Pixel', 'date': DateTime(2026, 3, 22)});

      await _pump(tester, {'open': (_) => const AddPhotoSheet()});
      await _open(tester);
      expect(_banner, findsOneWidget);
      expect(find.text(AppStrings.tapToSelectImage), findsNothing); // image restored
      expect(find.text('22 Mar 2026'), findsOneWidget);

      await _tapVisible(tester, find.widgetWithText(FilledButton, AppStrings.saveMemory));
      expect(_saves.single, 'photo:upload:Pixel');
      expect(FormDraftStore.has('photo:new'), isFalse);
    });
  });

  // ── Thought ──
  group('Thought sheet', () {
    testWidgets('new: restores content and tags; save clears', (tester) async {
      await _pump(tester, {'open': (_) => const AddThoughtSheet()});

      await _open(tester);
      await tester.enterText(_field(AppStrings.thoughtContentLabel), 'Stay curious');
      await tester.enterText(_field(AppStrings.thoughtTagsLabel), 'mindset');
      await _tapOutside(tester);

      await _open(tester);
      expect(_banner, findsOneWidget);
      expect(_text(tester, AppStrings.thoughtContentLabel), 'Stay curious');
      expect(_text(tester, AppStrings.thoughtTagsLabel), 'mindset');

      await _tapVisible(tester, find.widgetWithText(FilledButton, AppStrings.thoughtSave));
      expect(_saves.single, 'thought:create:Stay curious:mindset');
      await _open(tester);
      expect(_banner, findsNothing);
    });

    testWidgets('a failed save keeps the sheet open and the draft', (tester) async {
      _saveOk = false;
      await _pump(tester, {'open': (_) => const AddThoughtSheet()});
      await _open(tester);
      await tester.enterText(_field(AppStrings.thoughtContentLabel), 'Do hard things');
      await _tapVisible(tester, find.widgetWithText(FilledButton, AppStrings.thoughtSave));
      expect(_field(AppStrings.thoughtContentLabel), findsOneWidget); // still open
      await _tapOutside(tester);
      await _open(tester);
      expect(_text(tester, AppStrings.thoughtContentLabel), 'Do hard things');
    });

    testWidgets('edit: drafts are per thought and Discard returns to the saved text', (tester) async {
      await _pump(tester, {
        'A': (_) => AddThoughtSheet(thought: _thought('t1', 'Original A')),
        'B': (_) => AddThoughtSheet(thought: _thought('t2', 'Original B')),
      });

      await _open(tester, 'A');
      await tester.enterText(_field(AppStrings.thoughtContentLabel), 'Edited A');
      await _tapOutside(tester);

      await _open(tester, 'B');
      expect(_banner, findsNothing);
      expect(_text(tester, AppStrings.thoughtContentLabel), 'Original B');
      await _tapOutside(tester);

      await _open(tester, 'A');
      expect(_text(tester, AppStrings.thoughtContentLabel), 'Edited A');
      await _tapVisible(tester, find.text(AppStrings.discardDraft));
      expect(_text(tester, AppStrings.thoughtContentLabel), 'Original A');
      expect(tester.takeException(), isNull);
    });
  });
}
