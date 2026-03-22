import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';

import 'package:chronicle/features/dashboard/presentation/widgets/insights_carousel.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/expense_analytics_card.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/todo_analytics_card.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/health_mini_card.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/activity_stat_item.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final notifier = ref.read(dashboardControllerProvider.notifier);
    final theme = Theme.of(context);

    // Error State
    if (state.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                ),
                AppSpacing.gapLg,
                Text(
                  'Something went wrong', 
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                AppSpacing.gapSm,
                Text(
                  state.errorMessage!, 
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapXl,
                FilledButton.icon(
                  onPressed: () => notifier.setFilter(state.filter),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Day!', 
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Overview', 
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          _DashboardFilterDropdown(
            value: state.filter,
            onChanged: (val) {
              if (val != null) {
                notifier.setFilter(val);
              }
            },
          ),
          AppSpacing.hGapMd,
        ],
        toolbarHeight: 70,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => notifier.setFilter(state.filter),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Smart Insights Carousel
                  if (state.insights.isNotEmpty) ...[
                    InsightsCarousel(insights: state.insights),
                    AppSpacing.gapLg,
                  ],

                  // Expenses
                  ExpenseAnalyticsCard(analytics: state.expenseAnalytics),
                  AppSpacing.gapLg,

                  // Tasks
                  TodoAnalyticsCard(analytics: state.todoAnalytics),
                  AppSpacing.gapLg,

                  // Health & Hydration
                  Row(
                    children: [
                      Expanded(
                        child: HealthMiniCard(
                          icon: Icons.water_drop_rounded,
                          title: "Hydration",
                          value: "${state.healthAnalytics.hydrationPercentage.toStringAsFixed(0)}%",
                          subtitle: state.healthAnalytics.hydrationPercentage >= 100 
                              ? "Daily goal reached" 
                              : "Next: 1 glass",
                          color: Colors.blue,
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: HealthMiniCard(
                          icon: Icons.nights_stay_rounded,
                          title: "Sleep",
                          value: state.healthAnalytics.lastNightSleep != null 
                              ? "${state.healthAnalytics.lastNightSleep!.inHours}h ${state.healthAnalytics.lastNightSleep!.inMinutes.remainder(60)}m"
                              : "Not recorded",
                          subtitle: "Last night",
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),

                  AppSpacing.gapXl,

                  // Activity Summary Header
                  Row(
                    children: [
                      Text(
                        "RECENT MILESTONES", 
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        )
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ActivityStatItem(
                          icon: Icons.lightbulb_outline_rounded, 
                          count: state.activitySummary.newLearnings, 
                          label: "Lessons"
                        ),
                        ActivityStatItem(
                          icon: Icons.explore_outlined, 
                          count: state.activitySummary.placesVisited, 
                          label: "Explored"
                        ),
                        ActivityStatItem(
                          icon: Icons.auto_awesome_rounded, 
                          count: state.activitySummary.moodsLogged, 
                          label: "Moods"
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.gapXxl,
                ],
              ),
            ),
       floatingActionButton: FloatingActionButton.extended(
         onPressed: () => context.go('/expenses'),
         icon: const Icon(Icons.add_rounded),
         label: const Text('LOG ACTIVITY'),
         extendedTextStyle: theme.textTheme.labelLarge?.copyWith(
           fontWeight: FontWeight.w900,
           letterSpacing: 1,
         ),
       ),
    );
  }
}

class _DashboardFilterDropdown extends StatelessWidget {
  final DashboardDateFilter value;
  final ValueChanged<DashboardDateFilter?> onChanged;

  const _DashboardFilterDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DashboardDateFilter>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: theme.colorScheme.primary),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          dropdownColor: theme.colorScheme.surfaceContainerHigh,
          items: const [
            DropdownMenuItem(value: DashboardDateFilter.today, child: Text("Today")),
            DropdownMenuItem(value: DashboardDateFilter.thisWeek, child: Text("Weekly")),
            DropdownMenuItem(value: DashboardDateFilter.thisMonth, child: Text("Monthly")),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
