import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronicle/core/utils/date_ranges.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_filter_sheet.dart';
import 'package:chronicle/features/expenses/presentation/widgets/transaction_filter_sheet.dart';

Expense _expense(DateTime date) => Expense(
      id: date.toIso8601String(),
      userId: 'u',
      amount: 100,
      expenseDate: date,
      createdAt: date,
    );

Transaction _transaction(DateTime date) => Transaction(
      id: date.toIso8601String(),
      userId: 'u',
      personName: 'Sam',
      amount: 100,
      type: TransactionType.LEND,
      status: TransactionStatus.pending,
      date: date,
      createdAt: date,
    );

final _october = [DateTime(2026, 9, 30), DateTime(2026, 10, 1), DateTime(2026, 10, 31), DateTime(2026, 11, 1)];

class _FilteredController extends ExpenseController {
  final ExpenseState initial;

  _FilteredController(this.initial);

  @override
  ExpenseState build() => initial;
}

void main() {
  group('isWithinDays', () {
    final start = DateTime(2026, 10, 1);
    final end = DateTime(2026, 10, 31);

    test('includes both end days, whatever the time of day', () {
      expect(isWithinDays(DateTime(2026, 10, 1), start, end), isTrue);
      expect(isWithinDays(DateTime(2026, 10, 31, 23, 59), start, end), isTrue);
    });

    test('excludes the day before and the day after', () {
      expect(isWithinDays(DateTime(2026, 9, 30, 23, 59), start, end), isFalse);
      expect(isWithinDays(DateTime(2026, 11, 1), start, end), isFalse);
    });

    test('null bounds are open', () {
      expect(isWithinDays(DateTime(1999), null, end), isTrue);
      expect(isWithinDays(DateTime(2099), start, null), isTrue);
    });
  });

  // H04: a range ending 31 Oct used to include 1 Nov.
  test('expense history for October lists only October', () {
    final state = ExpenseState(
      expenses: [for (final d in _october) _expense(d)],
      expenseFilters: ExpenseFilters(startDate: DateTime(2026, 10, 1), endDate: DateTime(2026, 10, 31)),
    );
    expect(state.filteredExpenses.map((e) => e.expenseDate), unorderedEquals([DateTime(2026, 10, 1), DateTime(2026, 10, 31)]));
  });

  test('transaction history for October lists only October', () {
    final state = ExpenseState(
      transactions: [for (final d in _october) _transaction(d)],
      transactionFilters: TransactionFilters(startDate: DateTime(2026, 10, 1), endDate: DateTime(2026, 10, 31)),
    );
    expect(state.filteredTransactions.map((t) => t.date), unorderedEquals([DateTime(2026, 10, 1), DateTime(2026, 10, 31)]));
  });

  group('pickerBounds', () {
    final first = DateTime(2020);
    final last = DateTime(2026, 11, 17);

    test('keeps the defaults when the range fits or is absent', () {
      expect(pickerBounds(first: first, last: last), DateTimeRange(start: first, end: last));
      final inside = DateTimeRange(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31));
      expect(pickerBounds(first: first, last: last, initial: inside), DateTimeRange(start: first, end: last));
    });

    test('widens to fit a range outside the defaults', () {
      final outside = DateTimeRange(start: DateTime(2019, 12, 1), end: DateTime(2026, 11, 30));
      expect(pickerBounds(first: first, last: last, initial: outside), outside);
    });
  });

  // H05: opening the picker with a filter that ends after today (e.g. the
  // current month from "See all") used to fail the picker's assertion.
  group('date range picker opens with a filter ending after today', () {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day + 10);

    Future<void> openPicker(WidgetTester tester, ExpenseState initial, Widget sheet) async {
      // Wide enough that the sheets' rows fit under the default (non-app) theme.
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [expenseControllerProvider.overrideWith(() => _FilteredController(initial))],
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: sheet))),
      ));
      await tester.tap(find.byIcon(Icons.date_range));
      await tester.pumpAndSettle();
    }

    testWidgets('expenses', (tester) async {
      await openPicker(
        tester,
        ExpenseState(expenseFilters: ExpenseFilters(startDate: start, endDate: end)),
        const ExpenseFilterSheet(),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });

    testWidgets('transactions (filter starting before 2020)', (tester) async {
      await openPicker(
        tester,
        ExpenseState(transactionFilters: TransactionFilters(startDate: DateTime(2019, 12, 1), endDate: DateTime(2020, 1, 5))),
        const TransactionFilterSheet(),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });
  });
}
