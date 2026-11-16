// Vision board milestones: pure progress/status rules, and the goal details
// screen's milestones section (add, tick → progress, completion offer,
// reorder, rollback, missing-table notice) with an in-memory repository,
// light and dark at 360dp.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/features/vision_board/domain/milestone_progress.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_milestone.dart';
import 'package:chronicle/features/vision_board/domain/repositories/vision_board_repository.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';
import 'package:chronicle/features/vision_board/presentation/screens/vision_board_screen.dart';
import 'package:chronicle/features/vision_board/presentation/screens/vision_goal_details_screen.dart';
import 'helpers/ui_test_harness.dart';

VisionMilestone _m(String id, {bool done = false, int position = 0, String goalId = 'g1'}) =>
    VisionMilestone(id: id, goalId: goalId, title: 'Step $id', isDone: done, position: position);

VisionGoal _goal({int progress = 40, String status = GoalStatus.inProgress}) => VisionGoal(
      id: 'g1',
      userId: 'u',
      title: 'Run a half marathon',
      duration: '6m',
      progress: progress,
      status: status,
      isFavorite: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

/// In-memory [VisionBoardRepository].
class _FakeRepo implements VisionBoardRepository {
  VisionGoal goal;
  List<VisionMilestone> milestones;
  bool unavailable = false;
  bool failNextWrite = false;
  int _id = 0;

  _FakeRepo(this.goal, [this.milestones = const []]);

  void _maybeFail() {
    if (unavailable) throw const MilestonesUnavailableException();
    if (failNextWrite) {
      failNextWrite = false;
      throw const AppException('Network down');
    }
  }

  @override
  Future<List<VisionGoal>> getGoals() async => [goal];
  @override
  Future<void> createGoal(VisionGoal g) async {}
  @override
  Future<void> updateGoal(String id, VisionGoal g) async => goal = g;
  @override
  Future<void> deleteGoal(String id) async {}
  @override
  Future<void> toggleFavorite(String id, bool currentStatus) async {}
  @override
  Future<void> setGoalProgress(String goalId, int progress, {String? status}) async =>
      goal = goal.copyWith(progress: progress, status: status);

  @override
  Future<List<VisionMilestone>> getMilestones(String goalId) async {
    if (unavailable) throw const MilestonesUnavailableException();
    return milestones;
  }

  @override
  Future<Map<String, MilestoneCount>> getMilestoneCounts() async {
    if (unavailable) throw const MilestonesUnavailableException();
    return milestones.isEmpty ? {} : {'g1': MilestoneCount.of(milestones)};
  }

  @override
  Future<VisionMilestone> addMilestone(String goalId, String title, int position) async {
    _maybeFail();
    final m = VisionMilestone(id: 'new${_id++}', goalId: goalId, title: title, position: position);
    milestones = [...milestones, m];
    return m;
  }

  @override
  Future<void> updateMilestone(String id, {String? title, bool? isDone}) async {
    _maybeFail();
    milestones = [for (final m in milestones) m.id == id ? m.copyWith(title: title, isDone: isDone) : m];
  }

  @override
  Future<void> deleteMilestone(String id) async {
    _maybeFail();
    milestones = milestones.where((m) => m.id != id).toList();
  }

  @override
  Future<void> reorderMilestones(Map<String, int> positions) async {
    _maybeFail();
    milestones = [for (final m in milestones) positions.containsKey(m.id) ? m.copyWith(position: positions[m.id]) : m]
      ..sort((a, b) => a.position.compareTo(b.position));
  }
}

void main() {
  final themes = setUpUiTests();

  group('MilestoneProgress', () {
    test('percent: none → manual, rounds, only 100 when all done', () {
      expect(MilestoneProgress.percent([]), isNull);
      expect(MilestoneProgress.percent([_m('a'), _m('b'), _m('c')]), 0);
      expect(MilestoneProgress.percent([_m('a', done: true), _m('b'), _m('c')]), 33);
      expect(MilestoneProgress.percent([_m('a', done: true), _m('b', done: true), _m('c')]), 67);
      final almost = [for (var i = 0; i < 200; i++) _m('$i', done: i > 0)];
      expect(MilestoneProgress.percent(almost), 99);
      expect(MilestoneProgress.percent([_m('a', done: true)]), 100);
    });

    test('status follows the work but never auto-completes', () {
      expect(MilestoneProgress.statusFor(current: GoalStatus.notStarted, progress: 0), GoalStatus.notStarted);
      expect(MilestoneProgress.statusFor(current: GoalStatus.notStarted, progress: 20), GoalStatus.inProgress);
      expect(MilestoneProgress.statusFor(current: GoalStatus.inProgress, progress: 100), GoalStatus.inProgress);
      expect(MilestoneProgress.statusFor(current: GoalStatus.inProgress, progress: 0), GoalStatus.inProgress);
      expect(MilestoneProgress.statusFor(current: GoalStatus.completed, progress: 100), GoalStatus.completed);
      expect(MilestoneProgress.statusFor(current: GoalStatus.completed, progress: 75), GoalStatus.inProgress);
    });

    test('completion is offered only when everything is done and not yet achieved', () {
      final all = [_m('a', done: true), _m('b', done: true)];
      expect(MilestoneProgress.offerCompletion(items: all, status: GoalStatus.inProgress), isTrue);
      expect(MilestoneProgress.offerCompletion(items: all, status: GoalStatus.completed), isFalse);
      expect(MilestoneProgress.offerCompletion(items: [_m('a', done: true), _m('b')], status: GoalStatus.inProgress), isFalse);
      expect(MilestoneProgress.offerCompletion(items: [], status: GoalStatus.inProgress), isFalse);
    });

    test('reorder moves an item and renumbers positions', () {
      final items = [_m('a', position: 0), _m('b', position: 1), _m('c', position: 5)];
      final down = MilestoneProgress.reorder(items, 0, 3); // a → end
      expect(down.map((m) => m.id), ['b', 'c', 'a']);
      expect(down.map((m) => m.position), [0, 1, 2]);
      final up = MilestoneProgress.reorder(items, 2, 0); // c → top
      expect(up.map((m) => m.id), ['c', 'a', 'b']);
    });
  });

  group('Milestones section', () {
    late _FakeRepo repo;

    Future<void> pump(WidgetTester tester, {ThemeData? theme, Widget? screen}) => pumpAppScreen(
          tester,
          screen: screen ?? VisionGoalDetailsScreen(goal: repo.goal),
          theme: theme ?? themes.light,
          size: const Size(360, 1400),
          overrides: [visionBoardRepositoryProvider.overrideWithValue(repo)],
        );

    Finder progressText(int p) => find.text('$p%');

    for (final MapEntry(key: themeName, value: theme) in themes.all.entries) {
      testWidgets('renders with milestones at 360dp ($themeName)', (tester) async {
        repo = _FakeRepo(_goal(progress: 50), [_m('a', done: true), _m('b', position: 1)]);
        await pump(tester, theme: theme);
        expect(tester.takeException(), isNull);
        expect(find.text('Step a'), findsOneWidget);
        expect(find.textContaining('1 ${AppStrings.visionMilestonesOf} 2 ${AppStrings.visionMilestonesDone}'), findsOneWidget);
      });
    }

    testWidgets('adding the first milestone switches progress to milestones', (tester) async {
      repo = _FakeRepo(_goal(progress: 40));
      await pump(tester);
      expect(progressText(40), findsOneWidget);
      expect(find.text(AppStrings.visionProgressManualHint), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('milestone-add-field')), 'Run 5k');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Run 5k'), findsOneWidget);
      expect(repo.milestones.single.title, 'Run 5k');
      expect(progressText(0), findsOneWidget);
      expect(repo.goal.progress, 0);
      expect(find.text(AppStrings.visionProgressManualHint), findsNothing);
    });

    testWidgets('ticking updates progress and status; completion is offered, unticking reopens', (tester) async {
      repo = _FakeRepo(_goal(progress: 0, status: GoalStatus.notStarted), [_m('a'), _m('b', position: 1)]);
      await pump(tester);

      await tester.tap(find.text('Step a'));
      await tester.pump();
      expect(progressText(50), findsOneWidget);
      expect(repo.goal.progress, 50);
      expect(repo.goal.status, GoalStatus.inProgress);

      await tester.tap(find.text('Step b'));
      await tester.pump();
      expect(repo.goal.progress, 100);
      expect(repo.goal.status, GoalStatus.inProgress, reason: 'never auto-completes');
      expect(find.text(AppStrings.visionMarkAchieved), findsOneWidget);

      await tester.tap(find.text(AppStrings.visionMarkAchieved));
      await tester.pump();
      expect(repo.goal.status, GoalStatus.completed);
      expect(find.text(AppStrings.visionMarkAchieved), findsNothing);
      expect(find.text(AppStrings.visionGoalAchieved), findsOneWidget);

      await tester.tap(find.text('Step b'));
      await tester.pump();
      expect(repo.goal.progress, 50);
      expect(repo.goal.status, GoalStatus.inProgress);
    });

    testWidgets('a failed save rolls the tick back', (tester) async {
      repo = _FakeRepo(_goal(progress: 0), [_m('a'), _m('b', position: 1)]);
      await pump(tester);
      repo.failNextWrite = true;
      await tester.tap(find.text('Step a'));
      await tester.pump();
      expect(repo.milestones.first.isDone, isFalse);
      expect(progressText(0), findsOneWidget);
      expect(find.text('Network down'), findsOneWidget);
    });

    testWidgets('dragging the handle reorders and saves positions', (tester) async {
      repo = _FakeRepo(_goal(), [_m('a', position: 0), _m('b', position: 1), _m('c', position: 2)]);
      await pump(tester);

      final handle = find.byIcon(Icons.drag_indicator_rounded).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repo.milestones.first.id, isNot('a'));
      expect(repo.milestones.map((m) => m.position), [0, 1, 2]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without the table, the screen still renders with a notice', (tester) async {
      repo = _FakeRepo(_goal())..unavailable = true;
      await pump(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Run a half marathon'), findsOneWidget);
      expect(find.text(AppStrings.visionMilestonesUnavailable), findsOneWidget);
      expect(find.byKey(const ValueKey('milestone-add-field')), findsNothing);
    });

    testWidgets('goal cards show milestone counts', (tester) async {
      repo = _FakeRepo(_goal(progress: 50), [_m('a', done: true), _m('b', position: 1)]);
      await pump(tester, screen: const VisionBoardScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('1/2 ${AppStrings.visionMilestonesShort}'), findsOneWidget);
    });
  });
}
