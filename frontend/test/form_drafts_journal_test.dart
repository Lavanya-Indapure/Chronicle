// Form drafts for the journaling forms: input survives an accidental dismiss
// (tap outside the sheet) or leaving the screen, is restored with a
// "Draft restored" banner, and is cleared only by a successful save.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/services/form_draft_store.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/features/first_times/domain/models/first_time_experience.dart';
import 'package:chronicle/features/first_times/presentation/controllers/first_time_controller.dart';
import 'package:chronicle/features/first_times/presentation/screens/first_times_screen.dart';
import 'package:chronicle/features/learnings/domain/models/learning.dart';
import 'package:chronicle/features/learnings/presentation/controllers/learning_controller.dart';
import 'package:chronicle/features/learnings/presentation/screens/learnings_screen.dart';
import 'package:chronicle/features/moods/presentation/controllers/mood_controller.dart';
import 'package:chronicle/features/moods/presentation/screens/mood_board_screen.dart';
import 'package:chronicle/features/places/domain/models/place_visited.dart';
import 'package:chronicle/features/places/presentation/controllers/place_controller.dart';
import 'package:chronicle/features/places/presentation/screens/places_visited_screen.dart';

import 'helpers/ui_test_harness.dart';

// ── Fakes: empty lists; saves succeed (recorded) or fail on demand ──

bool _failSaves = false;
final _saved = <String>[];

class _FakeLearningController extends LearningController {
  @override
  LearningState build() => const LearningState();

  @override
  Future<void> addLearning(Learning learning) async {
    if (_failSaves) throw Exception('offline');
    _saved.add(learning.title);
  }
}

class _FakeFirstTimeController extends FirstTimeController {
  @override
  FirstTimeState build() => FirstTimeState(experiences: const []);

  @override
  Future<void> createExperience(FirstTimeExperience experience) async {
    if (_failSaves) throw Exception('offline');
    _saved.add(experience.title);
  }
}

class _FakePlaceController extends PlaceController {
  @override
  PlaceState build() => PlaceState(places: const []);

  @override
  Future<void> addPlace(PlaceVisited place) async {
    if (_failSaves) throw Exception('offline');
    _saved.add(place.placeName);
  }
}

class _FakeMoodController extends MoodController {
  @override
  MoodState build() => MoodState(moods: const []);

  @override
  Future<void> logMood(String mood, String? note) async {
    if (_failSaves) throw Exception('offline');
    _saved.add('$mood:$note');
  }
}

final _overrides = [
  learningControllerProvider.overrideWith(_FakeLearningController.new),
  firstTimeControllerProvider.overrideWith(_FakeFirstTimeController.new),
  placeControllerProvider.overrideWith(_FakePlaceController.new),
  moodControllerProvider.overrideWith(_FakeMoodController.new),
];

/// Tall enough that the sheets never cover the top of the screen, so a tap
/// there lands on the barrier.
const _tall = Size(360, 1400);

Future<void> _pump(WidgetTester tester, Widget screen) =>
    pumpAppScreen(tester, screen: screen, theme: setUpThemes.dark, size: _tall, overrides: _overrides);

Future<void> _openSheet(WidgetTester tester, String addFirstLabel) async {
  await tester.tap(find.text(addFirstLabel));
  await tester.pumpAndSettle();
}

/// Taps the dimmed area above the sheet — the "accidental" dismiss.
Future<void> _tapOutside(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextField, label);

bool _chipSelected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;

late TestThemes setUpThemes;

void main() {
  setUpThemes = setUpUiTests();

  setUp(() {
    FormDraftStore.clearAll();
    _failSaves = false;
    _saved.clear();
  });

  group('Learning sheet', () {
    testWidgets('draft survives tapping outside; save clears it', (tester) async {
      await _pump(tester, const LearningsScreen());
      await _openSheet(tester, AppStrings.learningsAddFirst);
      expect(find.byType(DraftRestoredBanner), findsNothing);

      await tester.enterText(_field(AppStrings.learningTitleLabel), 'Compound interest');
      await tester.tap(find.widgetWithText(ChoiceChip, AppStrings.learningCatFood));
      await tester.tap(find.byTooltip('5/5'));
      await tester.pump();
      await _tapOutside(tester);
      expect(find.text('Compound interest'), findsNothing);

      await _openSheet(tester, AppStrings.learningsAddFirst);
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(find.text('Compound interest'), findsOneWidget);
      expect(_chipSelected(tester, AppStrings.learningCatFood), isTrue);
      expect(find.text('5/5'), findsOneWidget);
      await captureSnapshot(tester, 'draft_learning_dark');

      await tester.tap(find.text(AppStrings.learningSave));
      await tester.pumpAndSettle();
      expect(_saved, ['Compound interest']);

      await _openSheet(tester, AppStrings.learningsAddFirst);
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(find.text('Compound interest'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed save keeps the sheet open and the draft', (tester) async {
      _failSaves = true;
      await _pump(tester, const LearningsScreen());
      await _openSheet(tester, AppStrings.learningsAddFirst);
      await tester.enterText(_field(AppStrings.learningTitleLabel), 'Offline lesson');
      await tester.tap(find.text(AppStrings.learningSave));
      await tester.pumpAndSettle();
      expect(find.text('Offline lesson'), findsOneWidget); // still open

      await _tapOutside(tester);
      await _openSheet(tester, AppStrings.learningsAddFirst);
      expect(find.text('Offline lesson'), findsOneWidget);
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
    });
  });

  group('First-time sheet', () {
    final happy = '${FirstFeeling.happy.emoji}  ${FirstFeeling.happy.label}';

    testWidgets('draft survives tapping outside; Discard resets; save clears', (tester) async {
      await _pump(tester, const FirstTimeExperiencesScreen());
      await _openSheet(tester, AppStrings.firstsAddFirst);

      await tester.enterText(_field(AppStrings.firstTitleLabel), 'First solo trip');
      await tester.tap(find.widgetWithText(ChoiceChip, happy));
      await tester.tap(find.byTooltip('3/5'));
      await tester.pump();
      await _tapOutside(tester);

      await _openSheet(tester, AppStrings.firstsAddFirst);
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(find.text('First solo trip'), findsOneWidget);
      expect(_chipSelected(tester, happy), isTrue);
      expect(find.text('3/5'), findsOneWidget);

      // Discard resets to the starting values.
      await tester.tap(find.text(AppStrings.discardDraft));
      await tester.pumpAndSettle();
      expect(find.text('First solo trip'), findsNothing);
      expect(_chipSelected(tester, happy), isFalse);
      expect(find.text('5/5'), findsOneWidget);

      await tester.enterText(_field(AppStrings.firstTitleLabel), 'First marathon');
      await tester.tap(find.text(AppStrings.firstSave));
      await tester.pumpAndSettle();
      expect(_saved, ['First marathon']);

      await _openSheet(tester, AppStrings.firstsAddFirst);
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Place sheet', () {
    testWidgets('draft survives tapping outside; save clears it', (tester) async {
      await _pump(tester, const PlacesVisitedScreen());
      await _openSheet(tester, AppStrings.placesAddFirst);

      await tester.enterText(_field(AppStrings.placeNameLabel), 'Hampi');
      await tester.enterText(_field(AppStrings.placeCityLabel), 'Karnataka');
      await tester.tap(find.byTooltip('2/5'));
      await tester.pump();
      await _tapOutside(tester);

      await _openSheet(tester, AppStrings.placesAddFirst);
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(find.text('Hampi'), findsOneWidget);
      expect(find.text('Karnataka'), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget);

      await tester.tap(find.text(AppStrings.placeSave));
      await tester.pumpAndSettle();
      expect(_saved, ['Hampi']);

      await _openSheet(tester, AppStrings.placesAddFirst);
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(find.text('Hampi'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opening and closing without typing leaves no draft', (tester) async {
      await _pump(tester, const PlacesVisitedScreen());
      await _openSheet(tester, AppStrings.placesAddFirst);
      await _tapOutside(tester);
      expect(FormDraftStore.has('place:new'), isFalse);
    });
  });

  group('Mood note', () {
    testWidgets('picked mood + note survive leaving the screen; logging clears it', (tester) async {
      await _pump(tester, const MoodBoardScreen());
      await tester.tap(find.text(AppStrings.moodHappy).first);
      await tester.pumpAndSettle();
      await tester.enterText(_field(AppStrings.moodNoteHint), 'Great workout');

      // Leave the screen, come back.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, const MoodBoardScreen());
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(find.text('Great workout'), findsOneWidget);

      await tester.tap(find.textContaining(AppStrings.moodLog));
      await tester.pumpAndSettle();
      expect(_saved, ['happy:Great workout']);
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(find.text('Great workout'), findsNothing);

      // Nothing pending → leaving the screen stores no draft.
      await tester.pumpWidget(const SizedBox());
      expect(FormDraftStore.has('mood:note'), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed log keeps the mood and note', (tester) async {
      _failSaves = true;
      await _pump(tester, const MoodBoardScreen());
      await tester.tap(find.text(AppStrings.moodHappy).first);
      await tester.pumpAndSettle();
      await tester.enterText(_field(AppStrings.moodNoteHint), 'Offline mood');
      await tester.tap(find.textContaining(AppStrings.moodLog));
      await tester.pumpAndSettle();
      expect(find.text('Offline mood'), findsOneWidget);
    });
  });
}
