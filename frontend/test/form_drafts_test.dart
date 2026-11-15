// Form drafts: input typed into a sheet survives an accidental dismiss
// (tap outside) and is restored when the same form reopens.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/services/form_draft_store.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/presentation/widgets/add_todo_sheet.dart';

import 'helpers/ui_test_harness.dart';

/// A screen with one button that opens [sheet] as a modal bottom sheet.
class _SheetLauncher extends StatelessWidget {
  final WidgetBuilder sheet;

  const _SheetLauncher({required this.sheet});

  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton(
          onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: sheet),
          child: const Text('open'),
        ),
      );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Taps the dimmed area above the sheet — the "accidental" dismiss.
Future<void> _tapOutside(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

void main() {
  final themes = setUpUiTests();
  setUp(FormDraftStore.clearAll);

  group('Add Todo sheet draft', () {
    late List<(String, String?, RecurrenceType)> saved;
    late bool saveSucceeds;

    Widget sheet(BuildContext _) => AddTodoSheet(
          onSubmit: (title, description, type) async {
            if (saveSucceeds) saved.add((title, description, type));
            return saveSucceeds;
          },
        );

    setUp(() {
      saved = [];
      saveSucceeds = true;
    });

    testWidgets('restores typed input after tapping outside, then Discard resets it', (tester) async {
      await pumpAppScreen(tester, screen: _SheetLauncher(sheet: sheet), theme: themes.dark);

      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsNothing);
      await tester.enterText(find.widgetWithText(TextFormField, AppStrings.todoTitle), 'Buy groceries');
      await tester.tap(find.text(RecurrenceType.daily.label));
      await tester.pump();
      await _tapOutside(tester);
      expect(find.text('Buy groceries'), findsNothing); // sheet closed

      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(find.text('Buy groceries'), findsOneWidget);
      final daily = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, RecurrenceType.daily.label));
      expect(daily.selected, isTrue);
      await captureSnapshot(tester, 'draft_restored_todo_dark');

      await tester.tap(find.text(AppStrings.discardDraft));
      await tester.pumpAndSettle();
      expect(find.text('Buy groceries'), findsNothing);
      expect(find.byType(DraftRestoredBanner), findsNothing);

      // Discarded → closing and reopening starts empty.
      await _tapOutside(tester);
      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a successful save clears the draft', (tester) async {
      await pumpAppScreen(tester, screen: _SheetLauncher(sheet: sheet), theme: themes.dark);

      await _open(tester);
      await tester.enterText(find.widgetWithText(TextFormField, AppStrings.todoTitle), 'Call mom');
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.addTodo));
      await tester.pumpAndSettle();
      expect(saved.single.$1, 'Call mom');

      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(find.text('Call mom'), findsNothing);
    });

    testWidgets('a failed save keeps the input as a draft', (tester) async {
      saveSucceeds = false;
      await pumpAppScreen(tester, screen: _SheetLauncher(sheet: sheet), theme: themes.dark);

      await _open(tester);
      await tester.enterText(find.widgetWithText(TextFormField, AppStrings.todoTitle), 'Pay rent');
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.addTodo));
      await tester.pumpAndSettle();
      await _tapOutside(tester);

      await _open(tester);
      expect(find.text('Pay rent'), findsOneWidget);
    });

    testWidgets('opening and closing without typing leaves no draft', (tester) async {
      await pumpAppScreen(tester, screen: _SheetLauncher(sheet: sheet), theme: themes.dark);
      await _open(tester);
      await _tapOutside(tester);
      expect(FormDraftStore.has('todo:new'), isFalse);
    });
  });
}
