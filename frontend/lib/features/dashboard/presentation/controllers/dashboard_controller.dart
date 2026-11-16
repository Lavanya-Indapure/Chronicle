import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/todos/presentation/controllers/todo_controller.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/learnings/presentation/controllers/learning_controller.dart';
import 'package:chronicle/features/places/presentation/controllers/place_controller.dart';
import 'package:chronicle/features/moods/presentation/controllers/mood_controller.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/todo_progress.dart';
import 'package:chronicle/features/health/domain/health_stats.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/learnings/domain/models/learning.dart';
import 'package:chronicle/features/places/domain/models/place_visited.dart';
import 'package:chronicle/features/moods/domain/models/mood_entry.dart';

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    // Initial fetch
    Future.microtask(_fetchData);
    return const DashboardState(isLoading: true);
  }

  void setFilter(DashboardDateFilter filter) {
    state = state.copyWith(filter: filter, isLoading: true);
    Future.microtask(_fetchData);
  }

  /// Re-fetches the current period in place (pull-to-refresh, after quick adds)
  /// without flipping back to the full-screen loading state.
  Future<void> refresh() => _fetchData();

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(filter: DashboardDateFilter.custom, customDateRange: range, isLoading: true);
    Future.microtask(_fetchData);
  }

  Future<void> _fetchData() async {
    try {
      final dateRange = _getEffectiveDateRange();
      final start = dateRange.start;
      final end = dateRange.end;

      // Dependencies
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final todoRepo = ref.read(todoRepositoryProvider);
      final healthRepo = ref.read(healthRepositoryProvider);
      final learningRepo = ref.read(learningRepositoryProvider);
      final placeRepo = ref.read(placeRepositoryProvider);
      final moodRepo = ref.read(moodRepositoryProvider);
      final now = DateTime.now();

      // Concurrent fetch for date ranges
      final results = await Future.wait([
        expenseRepo.getExpenses(start: start, end: end),
        todoRepo.getInstancesBetweenDates(start, end),
        healthRepo.getHydrationLogs(now), // Just get today's hydration
        learningRepo.getLearnings(), // Currently fetches all, filter in memory
        placeRepo.getPlaces(), // Currently fetches all, filter in memory
        moodRepo.getMoods(), // Currently fetches all, filter in memory
        healthRepo.getSleepSince(HealthStats.day(now).subtract(const Duration(days: 8))),
        healthRepo.getSettings(),
      ]);

      final expenses = results[0] as List<Expense>;
      final todos = results[1] as List<TodoInstance>;
      final hydrationLogs = results[2] as List<HydrationReminder>;
      // Typed (not raw `List`) so field typos are compile errors, not runtime crashes.
      final allLearnings = results[3] as List<Learning>;
      final allPlaces = results[4] as List<PlaceVisited>;
      final allMoods = results[5] as List<MoodEntry>;
      final sleepRecords = results[6] as List<SleepRecord>;
      final healthSettings = results[7] as HealthSettings;

      // --- Analytics Generation ---
      
      // 1. Expense Analytics
      double totalSpent = 0;
      double highestDayAmount = 0;
      DateTime? highestDay;
      final categoryBreakdown = <String, double>{};
      final chartData = <String, double>{};
      double possibleSavings = 0;

      for (final e in expenses) {
        totalSpent += e.amount;
        if (!e.isNecessary) possibleSavings += e.amount;
        
        final catName = e.category?.name ?? 'Uncategorized';
        categoryBreakdown[catName] = (categoryBreakdown[catName] ?? 0) + e.amount;
        
        final dateStr = e.expenseDate.toIso8601String().split('T').first;
        chartData[dateStr] = (chartData[dateStr] ?? 0) + e.amount;
      }

      for (final entry in chartData.entries) {
        if (entry.value > highestDayAmount) {
          highestDayAmount = entry.value;
          highestDay = DateTime.parse(entry.key);
        }
      }

      final daysDiff = end.difference(start).inDays + 1;
      final averageDaily = daysDiff > 0 ? (totalSpent / daysDiff) : totalSpent;

      // Warning message (simplified)
      String? expenseWarning;
      if (state.filter == DashboardDateFilter.thisMonth && totalSpent > 20000) {
        // Hardcoded example budget threshold, ideally fetch `getBudgets()`
        expenseWarning = "You are approaching your typical monthly budget.";
      }

      final expenseAnalytics = ExpenseAnalytics(
        totalSpent: totalSpent,
        averageDaily: averageDaily,
        highestDayAmount: highestDayAmount,
        highestDay: highestDay,
        categoryBreakdown: categoryBreakdown,
        possibleSavings: possibleSavings,
        chartData: chartData,
        warningMessage: expenseWarning,
      );

      // 2. Todo Analytics — totals follow the selected period; the heatmap and
      //    streaks always cover the last [TodoAnalytics.heatmapWeeks] weeks so
      //    a short filter (e.g. "Today") can't cut a streak short.
      final completedTasks = todos.where((t) => t.isCompleted).length;
      final completionRate = todos.isEmpty ? 0.0 : (completedTasks / todos.length) * 100;

      final today = DateTime.now();
      final historyInstances = await todoRepo.getInstancesBetweenDates(TodoAnalytics.heatmapStart(today), today);
      final dayStats = TodoProgress.dayStats(historyInstances);
      final streaks = TodoProgress.streaks(dayStats, today);
      final currentStreak = streaks.current;

      final todoAnalytics = TodoAnalytics(
        totalTasks: todos.length,
        completedTasks: completedTasks,
        completionPercentage: completionRate,
        currentStreak: currentStreak,
        bestStreak: streaks.best,
        dayStats: dayStats,
      );

      // 3. Health Analytics
      final hydrationSlots = HealthStats.hydrationSlots(healthSettings, hydrationLogs, now);
      final hydrationPercentage = HealthStats.hydrationFraction(hydrationSlots) * 100;
      final averageSleep = HealthStats.averageSleep(sleepRecords, now);
      final sleepBelowGoal = averageSleep != null && averageSleep < Duration(hours: healthSettings.sleepGoalHours);

      final healthAnalytics = HealthAnalytics(
        lastNightSleep: HealthStats.lastSleep(sleepRecords)?.duration,
        averageSleep: averageSleep,
        sleepWarning: sleepBelowGoal ? AppStrings.sleepWarningInsight : null,
        hydrationPercentage: hydrationPercentage,
        hydrationWarning: hydrationPercentage < 50 && now.hour > 18 ? "You need to drink more water today!" : null,
      );

      // 4. Activity Summary (filter in memory)
      final newLearnings = allLearnings.where((l) => _isWithinRange(l.logDate, start, end)).length;
      final placesVisited = allPlaces.where((p) => _isWithinRange(p.visitDate, start, end)).length;
      final moodsLogged = allMoods.where((m) => _isWithinRange(m.logDate, start, end)).length;

      final activitySummary = ActivitySummary(
        newLearnings: newLearnings,
        placesVisited: placesVisited,
        moodsLogged: moodsLogged,
      );

      // 5. Smart Insights
      final insights = <SmartInsight>[];
      if (possibleSavings > 0) {
        insights.add(SmartInsight(id: '1', message: "You spent ₹${possibleSavings.toStringAsFixed(0)} on unnecessary items. Consider saving this next time.", type: InsightType.warning));
      }
      if (currentStreak >= 3) {
        insights.add(SmartInsight(id: '2', message: "Great job! You are on a $currentStreak-day task completion streak! Keep it up.", type: InsightType.positive));
      }
      if (healthAnalytics.sleepWarning != null) {
        insights.add(SmartInsight(id: '4', message: healthAnalytics.sleepWarning!, type: InsightType.warning));
      }
      if (healthAnalytics.hydrationPercentage >= 80) {
        insights.add(SmartInsight(id: '3', message: "You are staying well hydrated today. Good job!", type: InsightType.positive));
      }

      state = state.copyWith(
        isLoading: false,
        clearError: true,
        expenseAnalytics: expenseAnalytics,
        todoAnalytics: todoAnalytics,
        healthAnalytics: healthAnalytics,
        activitySummary: activitySummary,
        insights: insights,
      );

    } catch (e, st) {
      debugPrint("Dashboard error: $e\n$st");
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  bool _isWithinRange(DateTime d, DateTime start, DateTime end) {
    return (d.isAfter(start) || d.isAtSameMomentAs(start)) && 
           (d.isBefore(end) || d.isAtSameMomentAs(end));
  }

  DateTimeRange _getEffectiveDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (state.filter) {
      case DashboardDateFilter.today:
        return DateTimeRange(start: today, end: today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)));
      case DashboardDateFilter.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: startOfWeek, end: now);
      case DashboardDateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case DashboardDateFilter.custom:
        return state.customDateRange ?? DateTimeRange(start: today, end: now);
    }
  }
}

final dashboardControllerProvider = NotifierProvider<DashboardController, DashboardState>(DashboardController.new);
