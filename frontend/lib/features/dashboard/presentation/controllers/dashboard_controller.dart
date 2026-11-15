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
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:collection/collection.dart'; // For groupBy

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
      final todayStr = DateTime.now().toIso8601String().split('T').first;

      // Dependencies
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final todoRepo = ref.read(todoRepositoryProvider);
      final hydrationRepo = ref.read(hydrationRepositoryProvider);
      final learningRepo = ref.read(learningRepositoryProvider);
      final placeRepo = ref.read(placeRepositoryProvider);
      final moodRepo = ref.read(moodRepositoryProvider);
      
      // Get Sleep State from Memory Mock
      final sleepState = ref.read(sleepControllerProvider);

      // Concurrent fetch for date ranges
      final results = await Future.wait([
        expenseRepo.getExpenses(start: start, end: end),
        todoRepo.getInstancesBetweenDates(start, end),
        hydrationRepo.getTodayLogs(), // Just get today's hydration
        learningRepo.getLearnings(), // Currently fetches all, filter in memory
        placeRepo.getPlaces(), // Currently fetches all, filter in memory
        moodRepo.getMoods(), // Currently fetches all, filter in memory
      ]);

      final expenses = results[0] as List<Expense>;
      final todos = results[1] as List<TodoInstance>;
      final hydrationLogs = results[2] as List<HydrationReminder>;
      final allLearnings = results[3] as List;
      final allPlaces = results[4] as List;
      final allMoods = results[5] as List;

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

      // 2. Todo Analytics
      int completedTasks = 0;
      final historyHeatmap = <String, bool>{};
      for (final t in todos) {
        if (t.isCompleted) completedTasks++;
        final dateStr = t.scheduledDate.toIso8601String().split('T').first;
        // Mark true if at least one task done on that day
        historyHeatmap[dateStr] = historyHeatmap[dateStr] == true || t.isCompleted;
      }
      final completionRate = todos.isEmpty ? 0.0 : (completedTasks / todos.length) * 100;
      
      // Calculate current streak (backward from today)
      int currentStreak = 0;
      DateTime checkDate = DateTime.now();
      while (true) {
        final dStr = checkDate.toIso8601String().split('T').first;
        if (historyHeatmap[dStr] == true) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      // Calculate best streak
      int bestStreak = 0;
      int tempStreak = 0;
      final sortedDates = historyHeatmap.keys.toList()..sort();
      for (int i = 0; i < sortedDates.length; i++) {
        if (historyHeatmap[sortedDates[i]] == true) {
           if (i > 0) {
             final prev = DateTime.parse(sortedDates[i-1]);
             final curr = DateTime.parse(sortedDates[i]);
             if (curr.difference(prev).inDays == 1) {
               tempStreak++;
             } else {
               tempStreak = 1;
             }
           } else {
             tempStreak = 1;
           }
           if (tempStreak > bestStreak) bestStreak = tempStreak;
        }
      }

      final todoAnalytics = TodoAnalytics(
        totalTasks: todos.length,
        completedTasks: completedTasks,
        completionPercentage: completionRate,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        historyHeatmap: historyHeatmap,
      );

      // 3. Health Analytics
      Duration? lastNightSleep;
      if (sleepState.entries.isNotEmpty) {
        lastNightSleep = sleepState.entries.first.duration;
      }
      
      final doneHydrations = hydrationLogs.where((l) => l.status == 'DONE').length;
      final hydrationPercentage = hydrationLogs.isEmpty ? 0.0 : (doneHydrations / 17) * 100; // Assuming 17 slots

      final healthAnalytics = HealthAnalytics(
        lastNightSleep: lastNightSleep,
        hydrationPercentage: hydrationPercentage,
        hydrationWarning: hydrationPercentage < 50 && DateTime.now().hour > 18 ? "You need to drink more water today!" : null,
      );

      // 4. Activity Summary (filter in memory)
      final newLearnings = allLearnings.where((l) => _isWithinRange(l.createdAt, start, end)).length;
      final placesVisited = allPlaces.where((p) => _isWithinRange(p.visitDate ?? DateTime.now(), start, end)).length;
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
