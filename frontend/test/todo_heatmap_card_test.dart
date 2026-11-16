// Smoke test for the dashboard's todo heatmap: renders at phone widths in
// both themes and fails on overflow or build exceptions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/todo_heatmap_card.dart';
import 'package:chronicle/features/todos/domain/todo_progress.dart';
import 'helpers/ui_test_harness.dart';

void main() {
  final themes = setUpUiTests();
  // A Wednesday, so the last column has future (blank) days.
  final today = DateTime(2026, 11, 18);
  final start = TodoAnalytics.heatmapStart(today);
  final stats = <DateTime, TodoDayStat>{
    for (var i = 0; i < 100; i++)
      DateTime(start.year, start.month, start.day + i): TodoDayStat(total: 4, completed: i % 5),
  };

  for (final MapEntry(key: themeName, value: theme) in themes.all.entries) {
    for (final size in [smallPhone, largePhone]) {
      testWidgets('heatmap renders without overflow ($themeName, ${size.width.toInt()}dp)', (tester) async {
        await pumpAppScreen(
          tester,
          theme: theme,
          size: size,
          navIndex: NavTab.dashboard,
          screen: ListView(
            padding: AppSpacing.paddingGutter,
            children: [TodoHeatmapCard(dayStats: stats, today: today)],
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(TodoHeatmapCard), findsOneWidget);
        // 16 weeks × 7 days, minus Thu–Sun after "today" → one tooltip each.
        expect(
          find.descendant(of: find.byType(TodoHeatmapCard), matching: find.byType(Tooltip)),
          findsNWidgets(TodoAnalytics.heatmapWeeks * 7 - 4),
        );
        await captureSnapshot(tester, 'todo_heatmap_${themeName}_${size.width.toInt()}');
      });
    }
  }

  testWidgets('heatmap renders with no data', (tester) async {
    await pumpAppScreen(
      tester,
      theme: themes.light,
      navIndex: NavTab.dashboard,
      screen: ListView(
        padding: AppSpacing.paddingGutter,
        children: [TodoHeatmapCard(dayStats: const {}, today: today)],
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
