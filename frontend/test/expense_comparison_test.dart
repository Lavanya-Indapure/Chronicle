// Expense comparisons: like-for-like period maths and the Compare card.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/expenses/domain/expense_comparison.dart';
import 'package:chronicle/features/expenses/domain/models/category.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/presentation/widgets/comparison_card.dart';
import 'helpers/ui_test_harness.dart';

const _food = Category(id: 'food', name: 'Food', type: 'expense');
const _travel = Category(id: 'travel', name: 'Travel', type: 'expense');

var _id = 0;
Expense _e(double amount, DateTime date, [Category? cat]) => Expense(
      id: 'e${_id++}',
      userId: 'u',
      amount: amount,
      categoryId: cat?.id,
      category: cat,
      expenseDate: date,
      createdAt: date,
    );

void main() {
  final themes = setUpUiTests();

  // Wednesday 18 Nov 2026, mid-afternoon.
  final now = DateTime(2026, 11, 18, 15);

  group('ExpenseComparison', () {
    test('day: today vs yesterday', () {
      final c = ExpenseComparison.compare([
        _e(300, DateTime(2026, 11, 18), _food),
        _e(200, DateTime(2026, 11, 17), _food),
        _e(999, DateTime(2026, 11, 16), _food),
      ], ComparePeriod.day, now);
      expect((c.currentTotal, c.previousTotal), (300.0, 200.0));
      expect(c.change, closeTo(0.5, 1e-9));
      expect(c.currentSeries, isEmpty);
    });

    test('week: Mon→today vs last Mon→same weekday, chart covers all of last week', () {
      final c = ExpenseComparison.compare([
        _e(100, DateTime(2026, 11, 16), _food), // this Mon
        _e(50, DateTime(2026, 11, 18), _travel), // this Wed (today)
        _e(80, DateTime(2026, 11, 9), _food), // last Mon
        _e(20, DateTime(2026, 11, 11), _food), // last Wed
        _e(500, DateTime(2026, 11, 13), _travel), // last Fri — after "this point"
      ], ComparePeriod.week, now);
      expect(c.currentStart, DateTime(2026, 11, 16));
      expect((c.previousStart, c.previousEnd), (DateTime(2026, 11, 9), DateTime(2026, 11, 11)));
      expect((c.currentTotal, c.previousTotal), (150.0, 100.0));
      expect(c.currentSeries, [100, 0, 50, null, null, null, null]);
      expect(c.previousSeries, [80, 0, 20, 0, 500, 0, 0]);
    });

    test('month: 1st→today vs same days last month; running totals', () {
      final c = ExpenseComparison.compare([
        _e(1000, DateTime(2026, 11, 1), _food),
        _e(500, DateTime(2026, 11, 18), _food),
        _e(700, DateTime(2026, 10, 5), _food),
        _e(300, DateTime(2026, 10, 25), _food), // after day 18 → not compared
      ], ComparePeriod.month, now);
      expect((c.previousStart, c.previousEnd), (DateTime(2026, 10, 1), DateTime(2026, 10, 18)));
      expect((c.currentTotal, c.previousTotal), (1500.0, 700.0));
      expect(c.currentSeries.length, 30);
      expect(c.currentSeries[17], 1500);
      expect(c.currentSeries[18], isNull);
      expect(c.previousSeries.length, 31);
      expect(c.previousSeries.last, 1000);
    });

    test('month: clamps to the shorter previous month and handles January', () {
      final march31 = ExpenseComparison.compare([], ComparePeriod.month, DateTime(2026, 3, 31));
      expect(march31.previousEnd, DateTime(2026, 2, 28));
      final jan = ExpenseComparison.compare([_e(10, DateTime(2025, 12, 3))], ComparePeriod.month, DateTime(2026, 1, 10));
      expect((jan.previousStart, jan.previousTotal), (DateTime(2025, 12, 1), 10.0));
      expect(jan.previousSeries.length, 31);
    });

    test('any two past months compare whole months', () {
      final c = ExpenseComparison.compareMonths([
        _e(100, DateTime(2026, 8, 2), _food),
        _e(50, DateTime(2026, 8, 31), _food),
        _e(70, DateTime(2026, 6, 30), _travel),
      ], DateTime(2026, 8), DateTime(2026, 6), now);
      expect((c.currentStart, c.currentEnd), (DateTime(2026, 8), DateTime(2026, 8, 31)));
      expect((c.previousStart, c.previousEnd), (DateTime(2026, 6), DateTime(2026, 6, 30)));
      expect((c.currentTotal, c.previousTotal), (150.0, 70.0));
      expect(c.currentSeries.whereType<double>().length, 31); // no future days
      expect(c.previousSeries.length, 30);
    });

    test('when either month is the current one, both stop at today’s day', () {
      final c = ExpenseComparison.compareMonths([
        _e(100, DateTime(2026, 8, 10)),
        _e(900, DateTime(2026, 8, 25)), // after the 18th → not compared
        _e(40, DateTime(2026, 11, 5)),
      ], DateTime(2026, 8), DateTime(2026, 11), now);
      expect(c.currentEnd, DateTime(2026, 8, 18));
      expect(c.previousEnd, DateTime(2026, 11, 18));
      expect((c.currentTotal, c.previousTotal), (100.0, 40.0));
      // Chart: August in full, November only up to today.
      expect(c.currentSeries.last, 1000);
      expect(c.previousSeries[18], isNull);
    });

    test('no previous spending → no percentage; category movers sorted by size', () {
      final c = ExpenseComparison.compare([
        _e(100, DateTime(2026, 11, 18), _food),
        _e(400, DateTime(2026, 11, 18), _travel),
        _e(50, DateTime(2026, 11, 18)),
      ], ComparePeriod.day, now);
      expect(c.change, isNull);
      expect(c.changes.map((x) => x.name), ['Travel', 'Food', null]);
      expect(c.changes.first.delta, 400);
    });
  });

  group('ComparisonCard', () {
    final expenses = [
      _e(100, DateTime(2026, 11, 16), _food),
      _e(450, DateTime(2026, 11, 18), _travel),
      _e(80, DateTime(2026, 11, 9), _food),
      _e(1200, DateTime(2026, 10, 3), _travel),
      _e(300, DateTime(2026, 11, 2), _food),
    ];

    Future<void> pump(WidgetTester tester, ThemeData theme, Size size, {DateTime? viewing}) => pumpAppScreen(
          tester,
          screen: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ComparisonCard(
                expenses: expenses,
                colorFor: (_) => Colors.teal,
                initialMonth: viewing ?? DateTime(2026, 11),
                firstMonth: DateTime(2026, 1),
                lastMonth: DateTime(2026, 11),
                now: now,
              ),
            ],
          ),
          theme: theme,
          size: size,
        );

    for (final MapEntry(key: themeName, value: theme) in themes.all.entries) {
      for (final size in [smallPhone, largePhone]) {
        testWidgets('day / week / month render without overflow ($themeName, ${size.width.toInt()}dp)', (tester) async {
          await pump(tester, theme, size);
          for (final tab in [AppStrings.compareDay, AppStrings.compareMonth, AppStrings.compareWeek]) {
            await tester.tap(find.text(tab));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: tab);
          }
        });
      }
    }

    testWidgets('week headline is like-for-like and names the biggest mover', (tester) async {
      await pump(tester, themes.light, smallPhone);
      expect(find.text(AppStrings.compareWeekSoFar), findsOneWidget);
      // ₹550 this week vs ₹80 by last Wednesday.
      expect(find.textContaining('${AppStrings.compareMoreThan} ${AppStrings.compareVsLastWeek}'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
    });

    testWidgets('month tab: pick the two months to compare', (tester) async {
      await pump(tester, themes.light, smallPhone);
      await tester.tap(find.text(AppStrings.compareMonth));
      await tester.pumpAndSettle();
      expect(find.text('Nov 2026'), findsWidgets);
      expect(find.text('Oct 2026'), findsWidgets);

      // Change the second month to August via the picker.
      await tester.tap(find.text('Oct 2026').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aug'));
      await tester.pumpAndSettle();
      expect(find.text('Aug 2026'), findsWidgets);
      // November is the current month, so August is cut at the 18th too.
      expect(find.text('1–18 Aug'), findsOneWidget);
      expect(find.text('${AppStrings.compareNothingIn} 1–18 Aug'), findsOneWidget);

      // Picking the month already on the other side swaps them.
      await tester.tap(find.text('Nov 2026').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aug'));
      await tester.pumpAndSettle();
      final buttons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton)).toList();
      expect(buttons, hasLength(2));
      expect(find.descendant(of: find.byWidget(buttons[0]), matching: find.text('Aug 2026')), findsOneWidget);
      expect(find.descendant(of: find.byWidget(buttons[1]), matching: find.text('Nov 2026')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('viewing a past month opens on the Month tab for that month', (tester) async {
      await pump(tester, themes.dark, smallPhone, viewing: DateTime(2026, 10));
      expect(find.text('Oct 2026'), findsWidgets);
      expect(find.text('Sep 2026'), findsWidgets);
      expect(find.text(AppStrings.compareWeekSoFar), findsNothing);
    });

    testWidgets('day with nothing yesterday says so instead of a percentage', (tester) async {
      await pump(tester, themes.light, smallPhone);
      await tester.tap(find.text(AppStrings.compareDay));
      await tester.pumpAndSettle();
      expect(find.text('${AppStrings.compareNothingBefore} ${AppStrings.compareVsYesterday}'), findsOneWidget);
    });
  });
}
