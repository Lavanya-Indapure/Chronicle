// Smoke tests for the redesigned Restaurants (list, add sheet, log-visit
// sheet) and Photos (grid, viewer, add sheet) screens: fake data, both
// themes, small and large phones; fail on any overflow or build exception.
// Harness + snapshot instructions: test/helpers/ui_test_harness.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/providers/signed_url_provider.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/features/photos/domain/models/photo.dart';
import 'package:chronicle/features/photos/presentation/controllers/photo_controller.dart';
import 'package:chronicle/features/photos/presentation/screens/photos_screen.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';
import 'package:chronicle/features/restaurants/presentation/screens/restaurant_details_screen.dart';
import 'package:chronicle/features/restaurants/presentation/screens/restaurants_screen.dart';

import 'helpers/ui_test_harness.dart';

// ── Fake data ──

DateTime _daysAgo(int n) => DateTime.now().subtract(Duration(days: n));

Restaurant _restaurant(
  String id,
  String name, {
  String address = '12th Main, Indiranagar',
  int visits = 1,
  double rating = 4,
  bool favourite = false,
  double? bill,
  String? food,
  bool withPhoto = false,
}) =>
    Restaurant(
      id: id,
      userId: 'u',
      name: name,
      address: address,
      visitCount: visits,
      isFavorite: favourite,
      rating: rating,
      latestBillAmount: bill,
      latestFoodItems: food,
      photos: [
        if (withPhoto) RestaurantPhoto(id: 'p$id', restaurantId: id, storagePath: 'u/$id.jpg', imageUrl: 'unused'),
      ],
      createdAt: _daysAgo(30),
      updatedAt: _daysAgo(int.parse(id)),
    );

final _sampleRestaurants = [
  _restaurant('1', 'Toit Brewpub', visits: 3, rating: 4.5, favourite: true, bill: 2450, food: 'Paneer tikka, mocktails', withPhoto: true),
  _restaurant('2', 'Meghana Foods', address: 'Residency Road, Ashok Nagar, Bengaluru 560025', visits: 1, rating: 4, bill: 689, food: 'Chicken biryani'),
  _restaurant('3', 'A very long restaurant name that should be truncated nicely', visits: 7, rating: 3.5),
  _restaurant('4', 'Third Wave Coffee', visits: 2, rating: 5, bill: 420, withPhoto: true),
];

Photo _photo(String id, int daysAgo, {String? caption}) => Photo(
      id: id,
      userId: 'u',
      storagePath: 'u/$id.jpg',
      imageUrl: 'unused',
      caption: caption,
      photoDate: _daysAgo(daysAgo),
      createdAt: _daysAgo(daysAgo),
    );

final _samplePhotos = [
  _photo('a', 0, caption: 'Sunset at Nandi Hills'),
  _photo('b', 2),
  _photo('c', 5, caption: 'Birthday dinner'),
  _photo('d', 9),
  _photo('e', 40, caption: 'Old friends'),
  _photo('f', 45),
];

/// Data for the current test; tests set these before pumping.
List<Restaurant> _restaurants = _sampleRestaurants;
List<Photo> _photos = _samplePhotos;

class _FakeRestaurantController extends RestaurantController {
  @override
  RestaurantState build() => RestaurantState(restaurants: _restaurants);

  @override
  Future<void> loadRestaurants() async {}

  @override
  Future<List<RestaurantVisit>> getVisitHistory(String id) async => const [];
}

class _FakePhotoController extends PhotoController {
  @override
  PhotoState build() => PhotoState(photos: _photos);

  @override
  Future<void> loadPhotos() async {}
}

Future<void> _pump(WidgetTester tester, Widget screen, ThemeData theme, {Size size = smallPhone}) => pumpAppScreen(
      tester,
      screen: screen,
      theme: theme,
      size: size,
      overrides: [
        restaurantControllerProvider.overrideWith(_FakeRestaurantController.new),
        photoControllerProvider.overrideWith(_FakePhotoController.new),
        // Images can't load in tests; StorageImage should show its placeholder.
        signedUrlProvider.overrideWith((ref, object) => Future<String>.error(Exception('offline'))),
      ],
    );

void main() {
  final themes = setUpUiTests();

  tearDown(() {
    _restaurants = _sampleRestaurants;
    _photos = _samplePhotos;
  });

  group('restaurants', () {
    for (final MapEntry(key: name, value: theme) in themes.all.entries) {
      for (final (sizeName, size) in [('small', smallPhone), ('large', largePhone)]) {
        testWidgets('list renders ($name, $sizeName)', (tester) async {
          await _pump(tester, const RestaurantsScreen(), theme, size: size);
          expect(tester.takeException(), isNull);
          expect(find.text('Toit Brewpub'), findsOneWidget);
          expect(find.textContaining('1 ${AppStrings.visitSingular}'), findsOneWidget);
          expect(find.textContaining('3 ${AppStrings.visitPlural}'), findsOneWidget);
          expect(find.text(AppFormatters.currency(2450)), findsOneWidget);
          if (sizeName == 'small') await captureSnapshot(tester, 'restaurants_list_$name');
        });
      }
    }

    testWidgets('favourites filter, then no-matches state', (tester) async {
      _restaurants = [_sampleRestaurants[1], _sampleRestaurants[2]]; // none favourite
      await _pump(tester, const RestaurantsScreen(), themes.dark);
      await tester.tap(find.text(AppStrings.filterFavourites));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.noMatchesTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state offers to add the first restaurant', (tester) async {
      _restaurants = const [];
      await _pump(tester, const RestaurantsScreen(), themes.dark);
      expect(find.text(AppStrings.addFirstRestaurant), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureSnapshot(tester, 'restaurants_empty_dark');
    });

    testWidgets('add restaurant sheet opens without overflow', (tester) async {
      await _pump(tester, const RestaurantsScreen(), themes.dark, size: const Size(360, 1400));
      await tester.tap(find.text(AppStrings.addRestaurant));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.logRestaurant), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureSnapshot(tester, 'restaurants_add_sheet_dark');
    });

    testWidgets('log visit sheet opens from details without overflow', (tester) async {
      await _pump(tester, RestaurantDetailsScreen(restaurant: _sampleRestaurants.first), themes.light, size: const Size(360, 1200));
      await tester.tap(find.text(AppStrings.visitedAgain));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.logVisit), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureSnapshot(tester, 'restaurants_visit_sheet_light');
    });
  });

  group('photos', () {
    for (final MapEntry(key: name, value: theme) in themes.all.entries) {
      for (final (sizeName, size) in [('small', smallPhone), ('large', largePhone)]) {
        testWidgets('grid renders grouped by month ($name, $sizeName)', (tester) async {
          await _pump(tester, const PhotosScreen(), theme, size: size);
          expect(tester.takeException(), isNull);
          expect(find.text(AppFormatters.monthYear(_samplePhotos.first.photoDate)), findsOneWidget);
          if (sizeName == 'small') await captureSnapshot(tester, 'photos_grid_$name');
        });
      }
    }

    testWidgets('empty state offers to add the first photo', (tester) async {
      _photos = const [];
      await _pump(tester, const PhotosScreen(), themes.light);
      expect(find.text(AppStrings.addFirstPhoto), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('viewer shows caption, date and delete', (tester) async {
      await _pump(tester, const PhotosScreen(), themes.dark);
      await tester.tap(find.bySemanticsLabel('Sunset at Nandi Hills'));
      await tester.pumpAndSettle();
      expect(find.text('Sunset at Nandi Hills'), findsOneWidget);
      expect(find.text(AppFormatters.dayMonthYear(_samplePhotos.first.photoDate)), findsOneWidget);
      expect(find.byTooltip(AppStrings.delete), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureSnapshot(tester, 'photos_viewer_dark');
    });

    testWidgets('add photo sheet opens without overflow', (tester) async {
      await _pump(tester, const PhotosScreen(), themes.dark);
      await tester.tap(find.text(AppStrings.addPhoto));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.addNewMemory), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureSnapshot(tester, 'photos_add_sheet_dark');
    });
  });
}
