// Budgets: which budget is in force, pace maths, and the Budgets section.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/expenses/domain/budget_status.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/presentation/widgets/budget_section.dart';
import 'helpers/ui_test_harness.dart';

Budget _budget(String id, double amount, BudgetType type, DateTime start, {DateTime? created}) => Budget(
      id: id,
      userId: 'u',
      amount: amount,
      type: type,
      startDate: start,
      createdAt: created ?? start,
    );

BudgetStatus _status(BudgetType type, double budget, double spent, DateTime today) {
  final (start, end) = type == BudgetType.weekly ? Budgets.weekOf(today) : Budgets.monthOf(today);
  return BudgetStatus(type: type, budget: budget, spent: spent, periodStart: start, periodEnd: end, today: today);
}

void main() {
  final themes = setUpUiTests();

  group('Budgets.effective', () {
    // Newest first, as the database returns them.
    final history = [
      _budget('m3', 30000, BudgetType.monthly, DateTime(2026, 11, 10)),
      _budget('w1', 5000, BudgetType.weekly, DateTime(2026, 10, 1)),
      _budget('m2', 25000, BudgetType.monthly, DateTime(2026, 9, 1)),
      _budget('m1', 20000, BudgetType.monthly, DateTime(2026, 6, 1)),
    ];

    test('uses the latest budget, not the oldest (old bug)', () {
      expect(Budgets.effective(history, BudgetType.monthly, DateTime(2026, 11, 18))!.amount, 30000);
      expect(Budgets.effective(history, BudgetType.weekly, DateTime(2026, 11, 18))!.amount, 5000);
    });

    test('a past date uses the budget in force then', () {
      expect(Budgets.effective(history, BudgetType.monthly, DateTime(2026, 10, 31))!.amount, 25000);
      expect(Budgets.effective(history, BudgetType.monthly, DateTime(2026, 7, 15))!.amount, 20000);
      expect(Budgets.effective(history, BudgetType.monthly, DateTime(2026, 5, 31)), isNull);
    });

    test('same start day: the most recently created wins', () {
      final sameDay = [
        _budget('a', 100, BudgetType.weekly, DateTime(2026, 11, 1), created: DateTime(2026, 11, 1, 9)),
        _budget('b', 200, BudgetType.weekly, DateTime(2026, 11, 1), created: DateTime(2026, 11, 1, 18)),
      ];
      expect(Budgets.effective(sameDay, BudgetType.weekly, DateTime(2026, 11, 2))!.id, 'b');
    });
  });

  group('BudgetStatus', () {
    // Wednesday 18 Nov 2026: day 3 of 7 of the week, day 18 of 30 of the month.
    final wed = DateTime(2026, 11, 18, 21);

    test('left, days left (incl. today) and per-day allowance', () {
      final s = _status(BudgetType.weekly, 7000, 2000, wed);
      expect((s.left, s.daysLeft, s.perDayLeft), (5000.0, 5, 1000.0));
      expect(s.elapsed, closeTo(3 / 7, 1e-9));
      expect(s.pace, BudgetPace.onTrack);
    });

    test('spending faster than time passes is "ahead"; over budget is "over"', () {
      expect(_status(BudgetType.weekly, 7000, 5000, wed).pace, BudgetPace.ahead);
      final over = _status(BudgetType.monthly, 30000, 31000, wed);
      expect(over.pace, BudgetPace.over);
      expect(over.perDayLeft, isNull);
    });

    test('a finished period has no days left', () {
      final (start, end) = Budgets.monthOf(DateTime(2026, 10));
      final s = BudgetStatus(
        type: BudgetType.monthly,
        budget: 25000,
        spent: 24000,
        periodStart: start,
        periodEnd: end,
        today: end.add(const Duration(days: 1)),
      );
      expect((s.isFinished, s.daysLeft, s.pace), (true, 0, BudgetPace.onTrack));
    });
  });

  group('BudgetSection', () {
    final wed = DateTime.now();

    Future<void> pump(WidgetTester tester, Widget section, ThemeData theme, Size size) => pumpAppScreen(
          tester,
          screen: ListView(padding: const EdgeInsets.all(20), children: [section]),
          theme: theme,
          size: size,
        );

    for (final MapEntry(key: themeName, value: theme) in themes.all.entries) {
      for (final size in [smallPhone, largePhone]) {
        testWidgets('weekly + monthly tiles, every pace ($themeName, ${size.width.toInt()}dp)', (tester) async {
          for (final (weekly, monthly) in [
            (_status(BudgetType.weekly, 7000, 100, wed), _status(BudgetType.monthly, 30000, 29999, wed)),
            (_status(BudgetType.weekly, 7000, 9000, wed), null),
          ]) {
            await pump(
              tester,
              BudgetSection(weekly: weekly, monthly: monthly, showWeekly: true, onEdit: (_) {}),
              theme,
              size,
            );
            expect(tester.takeException(), isNull);
          }
        });
      }
    }

    testWidgets('no budgets → "Set …" tiles that open the editor for that type', (tester) async {
      BudgetType? edited;
      await pump(
        tester,
        BudgetSection(weekly: null, monthly: null, showWeekly: true, onEdit: (t) => edited = t),
        themes.light,
        smallPhone,
      );
      expect(find.text(AppStrings.budgets), findsOneWidget);
      await tester.tap(find.text(AppStrings.setWeeklyBudgetCta));
      expect(edited, BudgetType.weekly);
      await tester.tap(find.text(AppStrings.setMonthlyBudgetCta));
      expect(edited, BudgetType.monthly);
    });

    testWidgets('past month: monthly only, titled with the month', (tester) async {
      final (start, end) = Budgets.monthOf(DateTime(2026, 10));
      final october = BudgetStatus(
        type: BudgetType.monthly,
        budget: 25000,
        spent: 26500,
        periodStart: start,
        periodEnd: end,
        today: end.add(const Duration(days: 1)),
      );
      await pump(
        tester,
        BudgetSection(weekly: null, monthly: october, showWeekly: false, pastMonth: DateTime(2026, 10), onEdit: (_) {}),
        themes.dark,
        smallPhone,
      );
      expect(find.text('${AppStrings.budgetFor} October'), findsOneWidget);
      expect(find.text(AppStrings.weekly), findsNothing);
      expect(find.text('${AppStrings.budgetOverBy} ₹1,500'), findsOneWidget);
      // A finished month has no per-day allowance line.
      expect(find.textContaining(AppStrings.perDaySuffix), findsNothing);
    });
  });
}
