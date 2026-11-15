// Smoke tests for the revamped Dashboard / Expenses / Todos / Vision Board /
// restaurant screens: render them with fake data at phone widths in both
// themes and fail on any layout overflow or build exception.
// Harness + snapshot instructions: test/helpers/ui_test_harness.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'helpers/ui_test_harness.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/domain/models/category.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:chronicle/features/expenses/presentation/widgets/month_switcher.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/presentation/controllers/todo_controller.dart';
import 'package:chronicle/features/todos/presentation/screens/todos_screen.dart';
import 'package:chronicle/core/providers/signed_url_provider.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';
import 'package:chronicle/features/restaurants/presentation/screens/restaurant_details_screen.dart';
import 'package:chronicle/features/learnings/presentation/controllers/learning_controller.dart';
import 'package:chronicle/features/learnings/presentation/screens/learnings_screen.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';
import 'package:chronicle/features/vision_board/presentation/screens/vision_board_screen.dart';


// ── Fake data ──

DateTime _daysAgo(int n) {
  final now = DateTime.now();
  // Stay inside the current month so "this month" totals include everything.
  return DateTime(now.year, now.month, math.max(1, now.day - n));
}

Category _cat(String id, String name) => Category(id: id, name: name, type: 'expense');

final _categories = [
  _cat('c1', 'Rent'),
  _cat('c2', 'Food'),
  _cat('c3', 'Transport'),
  _cat('c4', 'Shopping'),
  _cat('c5', 'Education'),
];

Expense _expense(String id, double amount, int daysAgo, Category? cat, {String? desc, bool necessary = true}) =>
    Expense(
      id: id,
      userId: 'u',
      amount: amount,
      description: desc,
      categoryId: cat?.id,
      isNecessary: necessary,
      expenseDate: _daysAgo(daysAgo),
      createdAt: _daysAgo(daysAgo),
      category: cat,
    );

final _expenses = [
  _expense('e1', 12000, 0, _categories[0], desc: 'November rent'),
  _expense('e2', 450, 0, _categories[1], desc: 'Groceries'),
  _expense('e3', 180, 1, _categories[2], desc: 'Uber to office'),
  _expense('e4', 2499, 1, _categories[3], desc: 'Sneakers', necessary: false),
  _expense('e5', 1200, 2, _categories[4], desc: 'Online course'),
  _expense('e6', 320, 3, _categories[1]),
  _expense('e7', 90, 4, null, desc: 'Parking'),
  // Last month, so the month switcher and "vs last month" badge have data.
  Expense(
    id: 'e8',
    userId: 'u',
    amount: 14200,
    description: 'Last month rent',
    categoryId: 'c1',
    expenseDate: DateTime(DateTime.now().year, DateTime.now().month - 1, 15),
    createdAt: DateTime(DateTime.now().year, DateTime.now().month - 1, 15),
    category: _categories[0],
  ),
  // Well in the past, to exercise the month picker's year stepper.
  Expense(
    id: 'e9',
    userId: 'u',
    amount: 900,
    description: 'Old concert tickets',
    categoryId: 'c4',
    expenseDate: DateTime(DateTime.now().year - 1, 3, 10),
    createdAt: DateTime(DateTime.now().year - 1, 3, 10),
    category: _categories[3],
  ),
];

final _transactions = [
  Transaction(
    id: 't1',
    userId: 'u',
    personName: 'Rahul',
    amount: 1500,
    type: TransactionType.LEND,
    status: TransactionStatus.pending,
    reason: 'Dinner',
    date: _daysAgo(2),
    createdAt: _daysAgo(2),
  ),
  Transaction(
    id: 't2',
    userId: 'u',
    personName: 'Priya',
    amount: 600,
    type: TransactionType.BORROW,
    status: TransactionStatus.pending,
    date: _daysAgo(5),
    createdAt: _daysAgo(5),
  ),
];

final _budgets = [
  Budget(id: 'b1', userId: 'u', amount: 5000, type: BudgetType.weekly, startDate: _daysAgo(6), createdAt: _daysAgo(6)),
  Budget(id: 'b2', userId: 'u', amount: 25000, type: BudgetType.monthly, startDate: _daysAgo(6), createdAt: _daysAgo(6)),
];

final _dashboardState = DashboardState(
  isLoading: false,
  expenseAnalytics: ExpenseAnalytics(
    totalSpent: 16739,
    averageDaily: 1116,
    highestDayAmount: 12450,
    highestDay: _daysAgo(0),
    possibleSavings: 2499,
    warningMessage: 'You spent 40% more than last week.',
    chartData: {
      for (var i = 0; i < 10; i++)
        _daysAgo(9 - i).toIso8601String().split('T').first: [400, 900, 650, 1800, 700, 1200, 300, 2499, 1200, 900][i]
            .toDouble(),
    },
  ),
  todoAnalytics: const TodoAnalytics(
    totalTasks: 8,
    completedTasks: 5,
    completionPercentage: 62.5,
    currentStreak: 4,
    bestStreak: 11,
  ),
  healthAnalytics: const HealthAnalytics(hydrationPercentage: 75, lastNightSleep: Duration(hours: 7, minutes: 20)),
  activitySummary: const ActivitySummary(newLearnings: 3, placesVisited: 1, moodsLogged: 6),
  insights: const [
    SmartInsight(id: '1', message: 'Great job! You are on a 4-day task streak.', type: InsightType.positive),
    SmartInsight(id: '2', message: 'You are staying well hydrated today.', type: InsightType.neutral),
  ],
);

// ── Fake controllers ──

class _FakeDashboardController extends DashboardController {
  @override
  DashboardState build() => _dashboardState;
}

TodoInstance _todo(String id, String title, {bool done = false, bool carried = false, String? note}) => TodoInstance(
      id: id,
      templateId: 'tpl-$id',
      userId: 'u',
      title: title,
      description: note,
      scheduledDate: _daysAgo(0),
      isCompleted: done,
      isCarriedForward: carried,
      createdAt: _daysAgo(0),
      updatedAt: _daysAgo(0),
    );

final _todoState = TodoState(
  groupedTodos: {
    RecurrenceType.daily: [
      _todo('1', 'Soak dryfruits', done: true),
      _todo('2', 'Massage your scalp'),
      _todo('3', 'Massage your Face', done: true),
      _todo('4', 'Massage your Feet'),
      _todo('5', 'Eat 🍌'),
      _todo('6', 'Eat 2 dates'),
      _todo('7', '5 mins Sadhguru Morning', note: 'Before breakfast'),
      _todo('8', '5 Mins Sadhguru Night'),
      _todo('9', 'Eat dryfruits'),
    ],
    RecurrenceType.weekly: [
      _todo('10', 'Exfoliate Face'),
      _todo('11', 'Drink Coconut Water', carried: true),
    ],
    RecurrenceType.none: [
      _todo('12', 'Renew passport and book the appointment slot for next week', carried: true),
    ],
  },
);

class _FakeTodoController extends TodoController {
  @override
  TodoState build() => _todoState;

  @override
  Future<void> loadTodayTodos({bool silent = false}) async {}
}

VisionGoal _goal(String id, String title, String status, int progress, {String? category, bool fav = false}) =>
    VisionGoal(
      id: id,
      userId: 'u',
      title: title,
      description: 'A short description of why this goal matters to me.',
      category: category,
      duration: '1y',
      targetDate: DateTime(2027, 6),
      progress: progress,
      status: status,
      isFavorite: fav,
      createdAt: _daysAgo(3),
      updatedAt: _daysAgo(1),
    );

/// Vision board goals for the current test; empty list = empty board.
List<VisionGoal> _visionGoals = [];

class _FakeVisionBoardController extends VisionBoardController {
  @override
  VisionBoardState build() => VisionBoardState(goals: _visionGoals);
}

final _restaurant = Restaurant(
  id: 'r1',
  userId: 'u',
  name: 'Toit Brewpub',
  address: '298, 100 Feet Road, Indiranagar',
  visitCount: 1,
  isFavorite: false,
  rating: 3,
  createdAt: _daysAgo(10),
  updatedAt: _daysAgo(10),
);

class _FakeRestaurantController extends RestaurantController {
  @override
  RestaurantState build() => RestaurantState(restaurants: [_restaurant]);

  @override
  Future<List<RestaurantVisit>> getVisitHistory(String id) async => [
        RestaurantVisit(
          id: 'v1',
          restaurantId: id,
          visitDate: _daysAgo(2),
          billAmount: 689,
          foodItems: 'Paneer tikka, mocktail',
          rating: 3,
          notes: 'Great music, slow service.',
          photos: const [
            RestaurantPhoto(id: 'p1', restaurantId: 'r1', storagePath: 'u/missing.jpg', imageUrl: 'unused'),
          ],
        ),
      ];
}

class _FakeLearningController extends LearningController {
  @override
  LearningState build() => const LearningState();
}

class _FakeExpenseController extends ExpenseController {
  @override
  ExpenseState build() => ExpenseState(
        expenses: _expenses,
        transactions: _transactions,
        budgets: _budgets,
        categories: _categories,
      );

  @override
  Future<void> loadAllData() async {}
}

// ── Harness ──

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Widget screen,
  required int navIndex,
  required ThemeData theme,
  required Size size,
}) =>
    pumpAppScreen(
      tester,
      screen: screen,
      navIndex: navIndex,
      theme: theme,
      size: size,
      overrides: [
        dashboardControllerProvider.overrideWith(_FakeDashboardController.new),
        expenseControllerProvider.overrideWith(_FakeExpenseController.new),
        todoControllerProvider.overrideWith(_FakeTodoController.new),
        visionBoardControllerProvider.overrideWith(_FakeVisionBoardController.new),
        learningControllerProvider.overrideWith(_FakeLearningController.new),
        restaurantControllerProvider.overrideWith(_FakeRestaurantController.new),
        // Simulate storage refusing the file (e.g. missing read permission).
        signedUrlProvider.overrideWith((ref, object) => Future<String>.error(Exception('Object not found'))),
      ],
    );

void main() {
  final testThemes = setUpUiTests();
  final dark = testThemes.dark;
  final themes = testThemes.all;
  final screens = <String, (Widget, int)>{
    'dashboard': (const DashboardScreen(), 0),
    'expenses': (const ExpensesScreen(), 2),
    'todos': (const TodosScreen(), 1),
  };
  // Tall viewports so the whole scrolling page is laid out (and captured).
  const widths = [360.0, 412.0];
  const height = 2600.0;

  for (final MapEntry(key: themeName, value: theme) in themes.entries) {
    for (final MapEntry(key: screenName, value: (screen, navIndex)) in screens.entries) {
      for (final width in widths) {
        testWidgets('$screenName renders without overflow ($themeName, ${width.toInt()}dp)', (tester) async {
          await _pumpScreen(tester, screen: screen, navIndex: navIndex, theme: theme, size: Size(width, height));
          expect(tester.takeException(), isNull);
          if (captureSnapshots && width == widths.last) {
            await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${screenName}_$themeName.png'));
          }
        });
      }
    }
  }

  testWidgets('expenses summary shows budgets, top categories and debts; all categories opens', (tester) async {
    await _pumpScreen(
      tester,
      screen: const ExpensesScreen(),
      navIndex: 2,
      theme: dark,
      size: const Size(360, height),
    );
    expect(tester.takeException(), isNull);
    // Both budget bars on the summary card (fake data sets weekly + monthly).
    expect(find.text(AppStrings.monthly), findsOneWidget);
    expect(find.text(AppStrings.weekly), findsOneWidget);
    // Compact category card + one-line debts row.
    expect(find.text(AppStrings.whereItWent), findsOneWidget);
    expect(find.text('${AppStrings.debts} · 2'), findsOneWidget);

    // "All categories" opens the full breakdown page.
    await tester.tap(find.textContaining(AppStrings.allCategories));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Shopping'), findsWidgets);
    if (captureSnapshots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/expenses_all_categories_dark.png'));
    }
  });

  testWidgets('expenses: month switcher and expense details sheet', (tester) async {
    await _pumpScreen(tester, screen: const ExpensesScreen(), navIndex: 2, theme: dark, size: const Size(360, 3000));
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);

    // Compared with last month (which has spending in the fake data).
    expect(find.textContaining('${AppStrings.vs} ${AppFormatters.shortMonth(lastMonth)}'), findsOneWidget);

    // Step back a month, then forward again.
    await tester.tap(find.byTooltip(AppStrings.previousMonth));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(MonthSwitcher), matching: find.text(AppFormatters.monthYear(lastMonth))), findsOneWidget);
    expect(find.text('Last month rent'), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.nextMonth));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(MonthSwitcher), matching: find.text(AppFormatters.monthYear(now))), findsOneWidget);

    // Tapping the month opens the picker: jump to March last year in 3 taps.
    final march = DateTime(now.year - 1, 3);
    await tester.tap(find.byTooltip(AppStrings.pickMonth));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.previousYear));
    await tester.pumpAndSettle();
    if (captureSnapshots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/month_picker_dark.png'));
    }
    await tester.tap(find.text(AppFormatters.shortMonth(march)));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(MonthSwitcher), matching: find.text(AppFormatters.monthYear(march))), findsOneWidget);
    expect(find.text('Old concert tickets'), findsOneWidget);

    // "This month" shortcut jumps back.
    await tester.tap(find.byTooltip(AppStrings.pickMonth));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.thisMonthShortcut));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(MonthSwitcher), matching: find.text(AppFormatters.monthYear(now))), findsOneWidget);

    // Tapping an expense opens its details with Edit / Delete.
    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.edit), findsOneWidget);
    expect(find.text(AppStrings.delete), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (captureSnapshots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/expense_details_dark.png'));
    }
  });

  testWidgets('form sheet scrolls instead of overflowing when the keyboard is open', (tester) async {
    // Small phone with the on-screen keyboard taking 300dp.
    await _pumpScreen(tester, screen: const LearningsScreen(), navIndex: 4, theme: dark, size: const Size(360, 640));
    tester.view.viewInsets = FakeViewPadding(bottom: 300 * tester.view.devicePixelRatio);
    // Empty list → the empty state's "add first" button opens the sheet.
    await tester.tap(find.text(AppStrings.learningsAddFirst));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (captureSnapshots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/sheet_keyboard_dark.png'));
    }
  });

  testWidgets('restaurant details shows a placeholder when a photo cannot load', (tester) async {
    await _pumpScreen(
      tester,
      screen: RestaurantDetailsScreen(restaurant: _restaurant),
      navIndex: 4,
      theme: dark,
      size: const Size(360, 800),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('1 ${AppStrings.visitSingular}'), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    if (captureSnapshots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/restaurant_details_dark.png'));
    }
  });

  group('vision board', () {
    tearDown(() => _visionGoals = []);

    for (final MapEntry(key: themeName, value: theme) in themes.entries) {
      testWidgets('empty board shows call to action ($themeName)', (tester) async {
        _visionGoals = [];
        await _pumpScreen(tester, screen: const VisionBoardScreen(), navIndex: 4, theme: theme, size: const Size(360, 800));
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.addFirstGoal), findsOneWidget);
        if (captureSnapshots) {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/vision_empty_$themeName.png'));
        }
      });

      testWidgets('goal list renders without overflow ($themeName)', (tester) async {
        _visionGoals = [
          _goal('1', 'Run a half marathon', 'in_progress', 45, category: 'Health', fav: true),
          _goal('2', 'Read 24 books this year', 'not_started', 0, category: 'Learning'),
          _goal('3', 'Build an emergency fund of six months of expenses', 'completed', 100, category: 'Finance'),
        ];
        await _pumpScreen(tester, screen: const VisionBoardScreen(), navIndex: 4, theme: theme, size: const Size(360, 1100));
        expect(tester.takeException(), isNull);
        // The selected "All" pill must be visible text, not blank.
        expect(find.text(AppStrings.statusAll), findsOneWidget);
        if (captureSnapshots) {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/vision_goals_$themeName.png'));
        }
      });
    }
  });
}
