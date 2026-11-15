// Smoke tests for the revamped Dashboard / Expenses screens and the floating
// nav bar: render them with fake data at phone widths in both themes and fail
// on any layout overflow or build exception.
//
// To also write PNG snapshots for visual review (FONT_DIR is optional and
// should hold Poppins-{Regular,Medium,SemiBold,Bold}.ttf for real text):
//   flutter test test/ui_revamp_smoke_test.dart --update-goldens \
//     --dart-define=CAPTURE=true --dart-define=FONT_DIR=/path/to/fonts

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/providers/supabase_provider.dart';
import 'package:chronicle/core/theme/app_theme.dart';
import 'package:chronicle/core/widgets/floating_nav_bar.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/domain/models/category.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/presentation/controllers/todo_controller.dart';
import 'package:chronicle/features/todos/presentation/screens/todos_screen.dart';
import 'package:chronicle/features/learnings/presentation/controllers/learning_controller.dart';
import 'package:chronicle/features/learnings/presentation/screens/learnings_screen.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';
import 'package:chronicle/features/vision_board/presentation/screens/vision_board_screen.dart';

const _capture = bool.fromEnvironment('CAPTURE');
const _fontDir = String.fromEnvironment('FONT_DIR');

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

const _navItems = [
  FloatingNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: AppStrings.dashboardLabel),
  FloatingNavItem(icon: Icons.check_circle_outline, selectedIcon: Icons.check_circle, label: AppStrings.todosLabel),
  FloatingNavItem(icon: Icons.bar_chart_rounded, selectedIcon: Icons.bar_chart_rounded, label: AppStrings.expensesLabel),
  FloatingNavItem(icon: Icons.favorite_outline, selectedIcon: Icons.favorite, label: AppStrings.healthLabel),
  FloatingNavItem(icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: AppStrings.moreLabel),
];

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Widget screen,
  required int navIndex,
  required ThemeData theme,
  required Size size,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserFirstNameProvider.overrideWithValue('Alex'),
        dashboardControllerProvider.overrideWith(_FakeDashboardController.new),
        expenseControllerProvider.overrideWith(_FakeExpenseController.new),
        todoControllerProvider.overrideWith(_FakeTodoController.new),
        visionBoardControllerProvider.overrideWith(_FakeVisionBoardController.new),
        learningControllerProvider.overrideWith(_FakeLearningController.new),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          body: screen,
          bottomNavigationBar: FloatingNavBar(
            items: _navItems,
            selectedIndex: navIndex,
            onSelected: (_) {},
            onAction: () {},
            actionLabel: AppStrings.quickAdd,
          ),
        ),
      ),
    ),
  );
  // Let entry animations (rings, donut) finish.
  await tester.pump(const Duration(seconds: 1));
}

/// Loads real fonts so captured snapshots show readable text and icons.
/// [fontDir] must contain Poppins-{Regular,Medium,SemiBold,Bold}.ttf.
Future<void> _loadSnapshotFonts(String fontDir) async {
  Future<ByteData> read(String path) async => ByteData.sublistView(await File(path).readAsBytes());

  // google_fonts asks for one family per weight, e.g. "Poppins_600".
  const weights = {'regular': 'Regular', '500': 'Medium', '600': 'SemiBold', '700': 'Bold'};
  for (final MapEntry(key: variant, value: file) in weights.entries) {
    await (FontLoader('Poppins_$variant')..addFont(read('$fontDir/Poppins-$file.ttf'))).load();
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(read('$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf'));
    await icons.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // google_fonts can't find Poppins in tests and reports that as an async
  // error; build the themes in a zone that swallows those so tests don't fail.
  late final ThemeData dark;
  late final ThemeData light;
  runZonedGuarded(() {
    dark = AppTheme.dark;
    light = AppTheme.light;
  }, (_, _) {});

  if (_capture && _fontDir.isNotEmpty) {
    setUpAll(() => _loadSnapshotFonts(_fontDir));
  }

  final themes = {'dark': dark, 'light': light};
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
          if (_capture && width == widths.last) {
            await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${screenName}_$themeName.png'));
          }
        });
      }
    }
  }

  testWidgets('expenses budgets tab renders without overflow', (tester) async {
    await _pumpScreen(
      tester,
      screen: const ExpensesScreen(),
      navIndex: 2,
      theme: dark,
      size: const Size(360, height),
    );
    await tester.tap(find.text(AppStrings.budgets).last);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.weeklyBudget), findsOneWidget);
    if (_capture) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/expenses_budgets_dark.png'));
    }
  });

  testWidgets('form sheet scrolls instead of overflowing when the keyboard is open', (tester) async {
    // Small phone with the on-screen keyboard taking 300dp.
    await _pumpScreen(tester, screen: const LearningsScreen(), navIndex: 4, theme: dark, size: const Size(360, 640));
    tester.view.viewInsets = FakeViewPadding(bottom: 300 * tester.view.devicePixelRatio);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).at(1)); // 0 = screen search box, 1 = first sheet field
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (_capture) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/sheet_keyboard_dark.png'));
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
        if (_capture) {
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
        if (_capture) {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/vision_goals_$themeName.png'));
        }
      });
    }
  });
}
