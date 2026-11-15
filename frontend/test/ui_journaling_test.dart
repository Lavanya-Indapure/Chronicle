// Smoke tests for the redesigned journaling screens (Thoughts, Learnings,
// First-times, Mood board, Places visited): render with fake data and empty
// data in both themes at phone widths; fail on overflow or build exceptions.
// Harness + snapshot instructions: test/helpers/ui_test_harness.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/first_times/domain/models/first_time_experience.dart';
import 'package:chronicle/features/first_times/presentation/controllers/first_time_controller.dart';
import 'package:chronicle/features/first_times/presentation/screens/first_times_screen.dart';
import 'package:chronicle/features/learnings/domain/models/learning.dart';
import 'package:chronicle/features/learnings/presentation/controllers/learning_controller.dart';
import 'package:chronicle/features/learnings/presentation/screens/learnings_screen.dart';
import 'package:chronicle/features/moods/domain/models/mood_entry.dart';
import 'package:chronicle/features/moods/presentation/controllers/mood_controller.dart';
import 'package:chronicle/features/moods/presentation/screens/mood_board_screen.dart';
import 'package:chronicle/features/places/domain/models/place_visited.dart';
import 'package:chronicle/features/places/presentation/controllers/place_controller.dart';
import 'package:chronicle/features/places/presentation/screens/places_visited_screen.dart';
import 'package:chronicle/features/thoughts/domain/models/thought.dart';
import 'package:chronicle/features/thoughts/presentation/controllers/thought_controller.dart';
import 'package:chronicle/features/thoughts/presentation/screens/thoughts_screen.dart';

import 'helpers/ui_test_harness.dart';

// ── Fake data (toggled empty per test) ──

DateTime _daysAgo(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - n);
}

bool _empty = false;

final _thoughts = [
  Thought(
    id: 't1',
    userId: 'u',
    content: 'The best time to plant a tree was 20 years ago. The second best time is now.',
    tags: 'motivation, life',
    isFavorite: true,
    createdAt: _daysAgo(1),
    updatedAt: _daysAgo(1),
  ),
  Thought(
    id: 't2',
    userId: 'u',
    content: 'Simplicity is the ultimate sophistication.',
    tags: 'design',
    isFavorite: false,
    createdAt: _daysAgo(12),
    updatedAt: _daysAgo(12),
  ),
  Thought(
    id: 't3',
    userId: 'u',
    content: 'Write it down before you forget it.',
    isFavorite: false,
    createdAt: _daysAgo(40),
    updatedAt: _daysAgo(40),
  ),
];

final _learnings = [
  Learning(
    id: 'l1',
    userId: 'u',
    title: 'Index funds beat most active funds over 15 years',
    description: 'Low fees compound just like returns do.',
    category: 'finance',
    source: 'The Psychology of Money',
    usefulnessRating: 5,
    logDate: _daysAgo(2),
  ),
  Learning(
    id: 'l2',
    userId: 'u',
    title: 'Flutter keys keep state when widgets move',
    category: 'technology',
    usefulnessRating: 4,
    logDate: _daysAgo(5),
  ),
  Learning(
    id: 'l3',
    userId: 'u',
    title: 'Soak lentils overnight to cook faster',
    category: 'food',
    source: 'Mom',
    usefulnessRating: 3,
    logDate: _daysAgo(45),
  ),
];

final _firsts = [
  FirstTimeExperience(
    id: 'f1',
    userId: 'u',
    title: 'First solo trip abroad',
    description: 'Navigated Tokyo’s metro without getting lost (mostly).',
    logDate: _daysAgo(3),
    emotion: 'excited',
    rating: 5,
    location: 'Tokyo',
  ),
  FirstTimeExperience(
    id: 'f2',
    userId: 'u',
    title: 'Gave a conference talk',
    logDate: _daysAgo(60),
    emotion: 'nervous',
    rating: 4,
  ),
];

final _moods = [
  MoodEntry(id: 'm1', userId: 'u', logDate: _daysAgo(0), mood: 'happy', note: 'Great workout this morning'),
  MoodEntry(id: 'm2', userId: 'u', logDate: _daysAgo(1), mood: 'tired'),
  MoodEntry(id: 'm3', userId: 'u', logDate: _daysAgo(2), mood: 'happy'),
  MoodEntry(id: 'm4', userId: 'u', logDate: _daysAgo(4), mood: 'stressed', note: 'Deadline week'),
  MoodEntry(id: 'm5', userId: 'u', logDate: _daysAgo(9), mood: 'excited'),
  MoodEntry(id: 'm6', userId: 'u', logDate: _daysAgo(35), mood: 'sad'),
];

final _places = [
  PlaceVisited(
    id: 'p1',
    userId: 'u',
    placeName: 'Fushimi Inari Shrine',
    city: 'Kyoto',
    visitDate: _daysAgo(3),
    description: 'Thousands of orange torii gates up the mountain.',
    rating: 5,
  ),
  PlaceVisited(id: 'p2', userId: 'u', placeName: 'Marine Drive', city: 'Mumbai', visitDate: _daysAgo(20), rating: 4),
  PlaceVisited(id: 'p3', userId: 'u', placeName: 'Hampi ruins', city: 'Hampi', visitDate: _daysAgo(70), rating: 5),
];

// ── Fake controllers (no Supabase) ──

class _FakeThoughtController extends ThoughtController {
  @override
  ThoughtState build() => ThoughtState(thoughts: _empty ? const [] : _thoughts);
}

class _FakeLearningController extends LearningController {
  @override
  LearningState build() => LearningState(learnings: _empty ? const [] : _learnings);
}

class _FakeFirstTimeController extends FirstTimeController {
  @override
  FirstTimeState build() => FirstTimeState(experiences: _empty ? const [] : _firsts);
}

class _FakeMoodController extends MoodController {
  @override
  MoodState build() => MoodState(moods: _empty ? const [] : _moods);
}

class _FakePlaceController extends PlaceController {
  @override
  PlaceState build() => PlaceState(places: _empty ? const [] : _places);
}

final _overrides = [
  thoughtControllerProvider.overrideWith(_FakeThoughtController.new),
  learningControllerProvider.overrideWith(_FakeLearningController.new),
  firstTimeControllerProvider.overrideWith(_FakeFirstTimeController.new),
  moodControllerProvider.overrideWith(_FakeMoodController.new),
  placeControllerProvider.overrideWith(_FakePlaceController.new),
];

void main() {
  final themes = setUpUiTests();
  tearDown(() => _empty = false);

  final screens = <String, Widget>{
    'thoughts': const ThoughtsScreen(),
    'learnings': const LearningsScreen(),
    'firsts': const FirstTimeExperiencesScreen(),
    'moods': const MoodBoardScreen(),
    'places': const PlacesVisitedScreen(),
  };

  for (final MapEntry(key: themeName, value: theme) in themes.all.entries) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      for (final size in [smallPhone, largePhone]) {
        testWidgets('$name renders with data ($themeName, ${size.width.toInt()}dp)', (tester) async {
          await pumpAppScreen(tester, screen: screen, theme: theme, size: Size(size.width, 1400), overrides: _overrides);
          expect(tester.takeException(), isNull);
          if (size == largePhone) await captureSnapshot(tester, 'journal_${name}_$themeName');
        });
      }

      testWidgets('$name empty state ($themeName)', (tester) async {
        _empty = true;
        await pumpAppScreen(tester, screen: screen, theme: theme, overrides: _overrides);
        expect(tester.takeException(), isNull);
        await captureSnapshot(tester, 'journal_${name}_empty_$themeName');
      });
    }
  }

  testWidgets('empty states offer an add action', (tester) async {
    _empty = true;
    await pumpAppScreen(tester, screen: const LearningsScreen(), theme: themes.dark, overrides: _overrides);
    expect(find.text(AppStrings.learningsAddFirst), findsOneWidget);
  });

  testWidgets('learnings search with no match shows the no-results state', (tester) async {
    await pumpAppScreen(tester, screen: const LearningsScreen(), theme: themes.dark, overrides: _overrides);
    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.journalNoResultsTitle), findsOneWidget);
  });

  testWidgets('mood picker reveals note field and log button', (tester) async {
    await pumpAppScreen(tester, screen: const MoodBoardScreen(), theme: themes.dark, size: Size(smallPhone.width, 1600), overrides: _overrides);
    await tester.tap(find.text(AppStrings.moodExcited).first);
    await tester.pumpAndSettle();
    expect(find.textContaining(AppStrings.moodLog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureSnapshot(tester, 'journal_moods_picking_dark');
  });

  testWidgets('add sheets fit with the keyboard open', (tester) async {
    for (final screen in [const PlacesVisitedScreen(), const FirstTimeExperiencesScreen(), const LearningsScreen()]) {
      // Fresh tree each time, so the previous screen's open sheet is gone.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAppScreen(tester, screen: screen, theme: themes.dark, size: const Size(360, 640), overrides: _overrides);
      tester.view.viewInsets = FakeViewPadding(bottom: 300 * tester.view.devicePixelRatio);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (screen is PlacesVisitedScreen) await captureSnapshot(tester, 'journal_places_sheet_keyboard_dark');
      tester.view.resetViewInsets();
    }
  });

  testWidgets('add sheets render fully without keyboard', (tester) async {
    for (final (name, screen) in [
      ('learnings', const LearningsScreen()),
      ('firsts', const FirstTimeExperiencesScreen()),
      ('places', const PlacesVisitedScreen()),
      ('thoughts', const ThoughtsScreen()),
    ]) {
      // Fresh tree each time, so the previous screen's open sheet is gone.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAppScreen(tester, screen: screen, theme: themes.dark, size: const Size(360, 900), overrides: _overrides);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await captureSnapshot(tester, 'journal_${name}_sheet_dark');
    }
  });
}
