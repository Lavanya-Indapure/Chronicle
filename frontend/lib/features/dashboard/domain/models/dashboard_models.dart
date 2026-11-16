import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/domain/recurrence_rules.dart';
import 'package:chronicle/features/todos/domain/todo_progress.dart';

// Represents the global date range filter for the dashboard
enum DashboardDateFilter {
  today,
  thisWeek,
  thisMonth,
  custom,
}

class DashboardState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final DashboardDateFilter filter;
  final DateTimeRange? customDateRange;
  final ExpenseAnalytics expenseAnalytics;
  final TodoAnalytics todoAnalytics;
  final HealthAnalytics healthAnalytics;
  final ActivitySummary activitySummary;
  final List<SmartInsight> insights;

  const DashboardState({
    this.isLoading = true,
    this.errorMessage,
    this.filter = DashboardDateFilter.thisMonth,
    this.customDateRange,
    this.expenseAnalytics = const ExpenseAnalytics(),
    this.todoAnalytics = const TodoAnalytics(),
    this.healthAnalytics = const HealthAnalytics(),
    this.activitySummary = const ActivitySummary(),
    this.insights = const [],
  });

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    DashboardDateFilter? filter,
    DateTimeRange? customDateRange,
    ExpenseAnalytics? expenseAnalytics,
    TodoAnalytics? todoAnalytics,
    HealthAnalytics? healthAnalytics,
    ActivitySummary? activitySummary,
    List<SmartInsight>? insights,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filter: filter ?? this.filter,
      customDateRange: customDateRange ?? this.customDateRange,
      expenseAnalytics: expenseAnalytics ?? this.expenseAnalytics,
      todoAnalytics: todoAnalytics ?? this.todoAnalytics,
      healthAnalytics: healthAnalytics ?? this.healthAnalytics,
      activitySummary: activitySummary ?? this.activitySummary,
      insights: insights ?? this.insights,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        filter,
        customDateRange,
        expenseAnalytics,
        todoAnalytics,
        healthAnalytics,
        activitySummary,
        insights,
      ];
}

class ExpenseAnalytics extends Equatable {
  final double totalSpent;
  final double averageDaily;
  final double highestDayAmount;
  final DateTime? highestDay;
  final Map<String, double> categoryBreakdown;
  final double? budgetBudget; // Optional budget integration
  final String? warningMessage;
  final double possibleSavings; // e.g. amount spent on 'unnecessary' things
  // Daily totals for the chart: { "2023-10-01": 150.0, ... }
  final Map<String, double> chartData;

  const ExpenseAnalytics({
    this.totalSpent = 0.0,
    this.averageDaily = 0.0,
    this.highestDayAmount = 0.0,
    this.highestDay,
    this.categoryBreakdown = const {},
    this.budgetBudget,
    this.warningMessage,
    this.possibleSavings = 0.0,
    this.chartData = const {},
  });

  @override
  List<Object?> get props => [
        totalSpent,
        averageDaily,
        highestDayAmount,
        highestDay,
        categoryBreakdown,
        budgetBudget,
        warningMessage,
        possibleSavings,
        chartData,
      ];
}

class TodoAnalytics extends Equatable {
  final int totalTasks;
  final int completedTasks;
  final double completionPercentage;
  final int currentStreak;
  final int bestStreak;

  /// Per-day completion for the heatmap, keyed by date (time stripped),
  /// covering [heatmapWeeks] weeks up to today.
  final Map<DateTime, TodoDayStat> dayStats;

  /// Weeks shown on the dashboard heatmap (and used for streaks).
  static const int heatmapWeeks = 16;

  /// Monday of the first heatmap column, so columns line up with weeks.
  static DateTime heatmapStart(DateTime today) {
    final monday = RecurrenceRules.periodStart(RecurrenceType.weekly, today);
    return DateTime(monday.year, monday.month, monday.day - (heatmapWeeks - 1) * DateTime.daysPerWeek);
  }

  const TodoAnalytics({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.completionPercentage = 0.0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.dayStats = const {},
  });

  @override
  List<Object?> get props => [totalTasks, completedTasks, completionPercentage, currentStreak, bestStreak, dayStats];
}

class HealthAnalytics extends Equatable {
  final Duration? lastNightSleep;
  final Duration? averageSleep;
  final String? sleepWarning;
  final double hydrationPercentage;
  final String? hydrationWarning;

  const HealthAnalytics({
    this.lastNightSleep,
    this.averageSleep,
    this.sleepWarning,
    this.hydrationPercentage = 0.0,
    this.hydrationWarning,
  });

  @override
  List<Object?> get props => [lastNightSleep, averageSleep, sleepWarning, hydrationPercentage, hydrationWarning];
}

class ActivitySummary extends Equatable {
  final int newLearnings;
  final int placesVisited;
  final int moodsLogged;

  const ActivitySummary({
    this.newLearnings = 0,
    this.placesVisited = 0,
    this.moodsLogged = 0,
  });

  @override
  List<Object?> get props => [newLearnings, placesVisited, moodsLogged];
}

enum InsightType { positive, warning, neutral }

class SmartInsight extends Equatable {
  final String id;
  final String message;
  final InsightType type;

  const SmartInsight({
    required this.id,
    required this.message,
    this.type = InsightType.neutral,
  });

  @override
  List<Object?> get props => [id, message, type];
}
