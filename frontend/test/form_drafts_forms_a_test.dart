// Form drafts for: expense (add + edit), debt, edit todo, vision goal
// (add + edit), book (add + edit). Typed input must survive an accidental
// dismiss (tap outside), be restored on reopen, be per-item for edit forms,
// and be cleared by a successful save (but kept after a failed one).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/services/form_draft_store.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/features/books/domain/models/book.dart';
import 'package:chronicle/features/books/presentation/controllers/book_controller.dart';
import 'package:chronicle/features/books/presentation/widgets/add_book_sheet.dart';
import 'package:chronicle/features/expenses/domain/models/category.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/widgets/add_expense_sheet.dart';
import 'package:chronicle/features/expenses/presentation/widgets/add_transaction_sheet.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/presentation/widgets/edit_todo_sheet.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';
import 'package:chronicle/features/vision_board/presentation/widgets/add_goal_sheet.dart';

import 'helpers/ui_test_harness.dart';

// ── Launcher ──

/// One button per entry; each opens its sheet as a modal bottom sheet.
class _SheetLauncher extends StatelessWidget {
  final Map<String, WidgetBuilder> sheets;

  const _SheetLauncher(this.sheets);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final MapEntry(key: label, value: sheet) in sheets.entries)
              FilledButton(
                onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: sheet),
                child: Text(label),
              ),
          ],
        ),
      );
}

/// Tall viewport so long sheets never cover the whole barrier.
const _tall = Size(412, 1400);

Future<void> _open(WidgetTester tester, [String label = 'open']) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Taps the dimmed area above the sheet — the "accidental" dismiss.
Future<void> _tapOutside(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

String _text(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(_field(label)).controller!.text;

// ── Fakes ──

final _categories = [
  const Category(id: 'c1', name: 'Food', type: 'expense'),
  const Category(id: 'c2', name: 'Rent', type: 'expense'),
];

Expense _expense(String id, double amount, String description) => Expense(
      id: id,
      userId: 'u',
      amount: amount,
      description: description,
      categoryId: 'c1',
      expenseDate: DateTime(2026, 11, 10),
      createdAt: DateTime(2026, 11, 10),
      category: _categories[0],
    );

class _FakeExpenseController extends ExpenseController {
  @override
  ExpenseState build() => ExpenseState(categories: _categories);
}

final List<VisionGoal> _createdGoals = [];
bool _goalSaveFails = false;

class _FakeVisionBoardController extends VisionBoardController {
  @override
  VisionBoardState build() => const VisionBoardState();

  @override
  Future<void> createGoal(VisionGoal goal) async {
    if (_goalSaveFails) {
      state = state.copyWith(errorMessage: 'Network error');
    } else {
      // Like the real controller (whose reload resets errorMessage), a
      // successful save leaves no error behind.
      state = state.copyWith();
      _createdGoals.add(goal);
    }
  }

  @override
  Future<void> updateGoal(String id, VisionGoal goal) async => _createdGoals.add(goal);
}

VisionGoal _goal(String id, String title) => VisionGoal(
      id: id,
      userId: 'u',
      title: title,
      duration: '1y',
      targetDate: DateTime(2027, 6),
      progress: 40,
      status: 'in_progress',
      isFavorite: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

final List<String> _savedBooks = [];

class _FakeBookController extends BookController {
  @override
  BookState build() => const BookState();

  @override
  Future<bool> createBook({
    required String name,
    String? author,
    String? takeaways,
    String status = 'reading',
    double? rating,
    bool isFavorite = false,
  }) async {
    _savedBooks.add(name);
    return true;
  }

  @override
  Future<bool> updateBook({
    required String id,
    required String name,
    String? author,
    String? takeaways,
    required String status,
    double? rating,
    required bool isFavorite,
  }) async {
    _savedBooks.add(name);
    return true;
  }

  @override
  Future<bool> deleteBook(String id) async => true;
}

Book _book(String id, String name) => Book(
      id: id,
      userId: 'u',
      name: name,
      author: 'Author $id',
      status: 'reading',
      rating: 4,
      isFavorite: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  final themes = setUpUiTests();
  setUp(() {
    FormDraftStore.clearAll();
    _createdGoals.clear();
    _goalSaveFails = false;
    _savedBooks.clear();
  });

  Future<void> pump(WidgetTester tester, Map<String, WidgetBuilder> sheets) => pumpAppScreen(
        tester,
        screen: _SheetLauncher(sheets),
        theme: themes.dark,
        size: _tall,
        overrides: [
          expenseControllerProvider.overrideWith(_FakeExpenseController.new),
          visionBoardControllerProvider.overrideWith(_FakeVisionBoardController.new),
          bookControllerProvider.overrideWith(_FakeBookController.new),
        ],
      );

  // ── Expense ──

  group('Add Expense draft', () {
    final saved = <double>[];
    Widget addSheet(BuildContext _) => AddExpenseSheet(
          onSubmit: ({required amount, description, categoryId, required isNecessary, required date}) async {
            saved.add(amount);
            return true;
          },
        );
    setUp(saved.clear);

    testWidgets('restores amount, description and the necessity switch', (tester) async {
      await pump(tester, {'open': addSheet});
      await _open(tester);
      await tester.enterText(_field(AppStrings.amount), '250');
      await tester.enterText(_field('Description (optional)'), 'Lunch');
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await _tapOutside(tester);

      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(_text(tester, AppStrings.amount), '250');
      expect(_text(tester, 'Description (optional)'), 'Lunch');
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a successful save clears the draft', (tester) async {
      await pump(tester, {'open': addSheet});
      await _open(tester);
      await tester.enterText(_field(AppStrings.amount), '99');
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.saveExpense));
      await tester.pumpAndSettle();
      expect(saved, [99]);

      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(_text(tester, AppStrings.amount), isEmpty);
    });
  });

  group('Edit Expense draft', () {
    final a = _expense('a', 120, 'Groceries');
    final b = _expense('b', 300, 'Dinner');
    Widget editSheet(Expense e) => AddExpenseSheet(
          initial: e,
          onSubmit: ({required amount, description, categoryId, required isNecessary, required date}) async => true,
        );

    testWidgets('drafts are per expense and Discard returns to the original values', (tester) async {
      await pump(tester, {'edit a': (_) => editSheet(a), 'edit b': (_) => editSheet(b)});

      await _open(tester, 'edit a');
      await tester.enterText(_field(AppStrings.amount), '150');
      await _tapOutside(tester);

      // Another expense isn't affected.
      await _open(tester, 'edit b');
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(_text(tester, AppStrings.amount), '300');
      await _tapOutside(tester);

      await _open(tester, 'edit a');
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(_text(tester, AppStrings.amount), '150');

      await tester.tap(find.text(AppStrings.discardDraft));
      await tester.pumpAndSettle();
      expect(_text(tester, AppStrings.amount), '120');
      expect(_text(tester, 'Description (optional)'), 'Groceries');
      expect(find.byType(DraftRestoredBanner), findsNothing);
    });
  });

  // ── Debt ──

  group('Add Debt draft', () {
    final saved = <String>[];
    Widget sheet(BuildContext _) => AddTransactionSheet(
          onSubmit: ({required personName, required amount, required type, reason, required date}) async {
            saved.add(personName);
            return true;
          },
        );
    setUp(saved.clear);

    testWidgets('restores person, amount and lend/borrow choice; save clears it', (tester) async {
      await pump(tester, {'open': sheet});
      await _open(tester);
      await tester.enterText(_field('Person Name'), 'Rahul');
      await tester.enterText(_field('Amount'), '500');
      await tester.tap(find.text('Borrow'));
      await tester.pump();
      await _tapOutside(tester);

      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(_text(tester, 'Person Name'), 'Rahul');
      expect(_text(tester, 'Amount'), '500');
      final segments = tester.widget<SegmentedButton<TransactionType>>(find.byType(SegmentedButton<TransactionType>));
      expect(segments.selected, {TransactionType.BORROW});

      await tester.tap(find.text('Log Borrowing'));
      await tester.pumpAndSettle();
      expect(saved, ['Rahul']);
      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(_text(tester, 'Person Name'), isEmpty);
    });
  });

  // ── Edit Todo ──

  group('Edit Todo draft', () {
    Widget sheet(String id, String title) => EditTodoSheet(
          draftId: id,
          currentTitle: title,
          currentType: RecurrenceType.daily,
          onSubmit: (title, description, type) async => true,
        );

    testWidgets('per todo, chips restored, Discard returns to the todo', (tester) async {
      await pump(tester, {'t1': (_) => sheet('t1', 'Soak dryfruits'), 't2': (_) => sheet('t2', 'Eat dates')});

      await _open(tester, 't1');
      await tester.enterText(_field(AppStrings.todoTitle), 'Soak almonds');
      await tester.tap(find.text(RecurrenceType.weekly.label));
      await tester.pump();
      await _tapOutside(tester);

      await _open(tester, 't2');
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(_text(tester, AppStrings.todoTitle), 'Eat dates');
      await _tapOutside(tester);

      await _open(tester, 't1');
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(_text(tester, AppStrings.todoTitle), 'Soak almonds');
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, RecurrenceType.weekly.label)).selected, isTrue);

      await tester.tap(find.text(AppStrings.discardDraft));
      await tester.pumpAndSettle();
      expect(_text(tester, AppStrings.todoTitle), 'Soak dryfruits');
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, RecurrenceType.daily.label)).selected, isTrue);
    });

    testWidgets('saving clears the draft', (tester) async {
      await pump(tester, {'t1': (_) => sheet('t1', 'Soak dryfruits')});
      await _open(tester, 't1');
      await tester.enterText(_field(AppStrings.todoTitle), 'Soak almonds');
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(FormDraftStore.has('todo:edit:t1'), isFalse);
    });
  });

  // ── Vision goal ──

  group('Vision goal draft', () {
    testWidgets('new goal: restores title + favourite; failed save keeps it, success clears it', (tester) async {
      await pump(tester, {'open': (_) => const AddGoalSheet()});
      await _open(tester);
      await tester.enterText(_field('Goal Title'), 'Run a marathon');
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await _tapOutside(tester);

      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(_text(tester, 'Goal Title'), 'Run a marathon');
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);

      // Failed save: sheet stays open, draft survives.
      _goalSaveFails = true;
      await tester.tap(find.text('Manifest Goal'));
      await tester.pumpAndSettle();
      expect(find.text('Manifest Goal'), findsOneWidget);
      await _tapOutside(tester);
      expect(FormDraftStore.has('goal:new'), isTrue);

      // Successful save clears it.
      _goalSaveFails = false;
      await _open(tester);
      await tester.tap(find.text('Manifest Goal'));
      await tester.pumpAndSettle();
      expect(_createdGoals.single.title, 'Run a marathon');
      expect(FormDraftStore.has('goal:new'), isFalse);
    });

    testWidgets('edit goal: per goal, Discard returns to the goal', (tester) async {
      await pump(tester, {
        'g1': (_) => AddGoalSheet(goal: _goal('g1', 'Learn Spanish')),
        'g2': (_) => AddGoalSheet(goal: _goal('g2', 'Save 1L')),
      });
      await _open(tester, 'g1');
      await tester.enterText(_field('Goal Title'), 'Learn Spanish B2');
      await _tapOutside(tester);

      await _open(tester, 'g2');
      expect(find.byType(DraftRestoredBanner), findsNothing);
      await _tapOutside(tester);

      await _open(tester, 'g1');
      expect(_text(tester, 'Goal Title'), 'Learn Spanish B2');
      await tester.tap(find.text(AppStrings.discardDraft));
      await tester.pumpAndSettle();
      expect(_text(tester, 'Goal Title'), 'Learn Spanish');
      expect(tester.takeException(), isNull);
    });
  });

  // ── Book ──

  group('Book draft', () {
    testWidgets('new book: restores title + status; save clears it', (tester) async {
      await pump(tester, {'open': (_) => const AddBookSheet()});
      await _open(tester);
      await tester.enterText(_field(AppStrings.bookTitle), 'Deep Work');
      await tester.tap(find.text(AppStrings.bookStatusCompleted));
      await tester.pumpAndSettle();
      await _tapOutside(tester);

      await _open(tester);
      expect(find.byType(DraftRestoredBanner), findsOneWidget);
      expect(_text(tester, AppStrings.bookTitle), 'Deep Work');
      expect(tester.widget<PillTabs<String>>(find.byType(PillTabs<String>)).selected, 'completed');
      await captureSnapshot(tester, 'draft_restored_book_dark');

      await tester.tap(find.text(AppStrings.addToLibrary));
      await tester.pumpAndSettle();
      expect(_savedBooks, ['Deep Work']);
      expect(FormDraftStore.has('book:new'), isFalse);
    });

    testWidgets('edit book: per book, Discard returns to the book', (tester) async {
      await pump(tester, {
        'b1': (_) => AddBookSheet(book: _book('b1', 'Atomic Habits')),
        'b2': (_) => AddBookSheet(book: _book('b2', 'Ikigai')),
      });
      await _open(tester, 'b1');
      await tester.enterText(_field(AppStrings.bookTitle), 'Atomic Habits (2nd read)');
      await _tapOutside(tester);

      await _open(tester, 'b2');
      expect(find.byType(DraftRestoredBanner), findsNothing);
      expect(_text(tester, AppStrings.bookTitle), 'Ikigai');
      await _tapOutside(tester);

      await _open(tester, 'b1');
      expect(_text(tester, AppStrings.bookTitle), 'Atomic Habits (2nd read)');
      await tester.tap(find.text(AppStrings.discardDraft));
      await tester.pumpAndSettle();
      expect(_text(tester, AppStrings.bookTitle), 'Atomic Habits');
      expect(tester.takeException(), isNull);
    });
  });
}
