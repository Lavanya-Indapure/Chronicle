// Smoke tests for the Life Lessons and Miscellaneous screens: fake data,
// both themes, small and large phones.
// Harness + snapshot instructions: test/helpers/ui_test_harness.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/life_lessons/domain/models/life_lesson.dart';
import 'package:chronicle/features/life_lessons/presentation/controllers/life_lesson_controller.dart';
import 'package:chronicle/features/miscellaneous/domain/models/misc_item.dart';
import 'package:chronicle/features/miscellaneous/presentation/controllers/misc_controller.dart';
import 'package:chronicle/features/more/presentation/screens/more_sub_screens.dart';

import 'helpers/ui_test_harness.dart';

// ── Fake data ──

final _now = DateTime.now();

LifeLesson _lesson(String id, String content, {String? title, List<String> tags = const [], bool fav = false}) =>
    LifeLesson(
      id: id,
      userId: 'u',
      title: title,
      content: content,
      tags: tags,
      isFavorite: fav,
      createdAt: _now,
      updatedAt: _now,
    );

final _sampleLessons = [
  _lesson('l1', 'Ask for help early — waiting only makes the problem bigger.',
      title: 'Ask early', tags: ['career', 'growth'], fav: true),
  _lesson('l2', 'Rest is part of the work, not a reward for finishing it.', tags: ['health']),
  _lesson('l3', 'People remember how you made them feel.', title: 'Kindness', tags: ['relationships']),
];

// Text-only items (an image item would need Supabase for its signed URL).
MiscItem _item(String id, {String? title, String? content}) =>
    MiscItem(id: id, userId: 'u', title: title, content: content, createdAt: _now, updatedAt: _now);

final _sampleItems = [
  _item('m1', title: 'Wi-Fi at grandma’s', content: 'Network: Sunrise_5G — password on the fridge.'),
  _item('m2', content: 'Gift ideas: pottery class, a good fountain pen, concert tickets.'),
];

List<LifeLesson> _lessons = [];
List<MiscItem> _items = [];

class _FakeLifeLessonController extends LifeLessonController {
  @override
  LifeLessonState build() => LifeLessonState(lessons: _lessons);

  @override
  Future<void> loadLessons() async {}
}

class _FakeMiscController extends MiscController {
  @override
  MiscState build() => MiscState(items: _items);

  @override
  Future<void> loadItems() async {}
}

void main() {
  final themes = setUpUiTests();
  const sizes = {'360': smallPhone, '412': largePhone};

  tearDown(() {
    _lessons = [];
    _items = [];
  });

  Future<void> pump(WidgetTester tester, Widget screen, {required ThemeData theme, Size size = smallPhone}) =>
      pumpAppScreen(
        tester,
        screen: screen,
        theme: theme,
        size: size,
        overrides: [
          lifeLessonControllerProvider.overrideWith(_FakeLifeLessonController.new),
          miscControllerProvider.overrideWith(_FakeMiscController.new),
        ],
      );

  for (final MapEntry(key: themeName, value: theme) in themes.all.entries) {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      testWidgets('Life lessons with data ($themeName, ${sizeName}dp)', (tester) async {
        _lessons = _sampleLessons;
        await pump(tester, const LifeLessonsScreen(), theme: theme, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('Ask early'), findsOneWidget);
        expect(find.text('#career'), findsWidgets);
        if (sizeName == '412') await captureSnapshot(tester, 'life_lessons_$themeName');
      });

      testWidgets('Miscellaneous with data ($themeName, ${sizeName}dp)', (tester) async {
        _items = _sampleItems;
        await pump(tester, const MiscellaneousScreen(), theme: theme, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text('Wi-Fi at grandma’s'), findsOneWidget);
        if (sizeName == '412') await captureSnapshot(tester, 'misc_$themeName');
      });
    }

    testWidgets('Empty states ($themeName)', (tester) async {
      await pump(tester, const LifeLessonsScreen(), theme: theme);
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.lifeLessonsEmptyTitle), findsOneWidget);

      await pump(tester, const MiscellaneousScreen(), theme: theme);
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.miscEmptyTitle), findsOneWidget);
    });
  }

  testWidgets('Life lessons: tag filter narrows the list; tapping a card opens the edit sheet', (tester) async {
    _lessons = _sampleLessons;
    await pump(tester, const LifeLessonsScreen(), theme: themes.dark, size: largePhone);

    await tester.tap(find.widgetWithText(ChoiceChip, '#career'));
    await tester.pumpAndSettle();
    expect(find.text('Kindness'), findsNothing);
    expect(find.text('Ask early'), findsOneWidget);

    await tester.tap(find.text('Ask early'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.lifeLessonEditTitle), findsOneWidget);
    expect(find.byTooltip(AppStrings.delete), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Life lessons: search with no matches shows the muted notice', (tester) async {
    _lessons = _sampleLessons;
    await pump(tester, const LifeLessonsScreen(), theme: themes.light, size: largePhone);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.journalNoResultsTitle), findsOneWidget);
  });

  testWidgets('Miscellaneous: saving an empty item asks for a note or picture', (tester) async {
    _items = _sampleItems;
    await pump(tester, const MiscellaneousScreen(), theme: themes.dark, size: largePhone);
    await tester.tap(find.text(AppStrings.miscAdd));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.miscNewTitle), findsWidgets);

    await tester.tap(find.text(AppStrings.miscSave));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.miscNeedsContent), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('LifeLesson.parseTags trims, drops blanks and de-duplicates', () {
    expect(LifeLesson.parseTags(' growth, Patience ,, growth,GROWTH '), ['growth', 'Patience']);
    expect(LifeLesson.parseTags('   '), isEmpty);
  });
}
