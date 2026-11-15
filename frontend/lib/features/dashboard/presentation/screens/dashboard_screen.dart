import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/hero_summary_card.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/activity_summary_row.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/glance_card.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/insight_card.dart';
import 'package:chronicle/features/dashboard/presentation/widgets/spending_chart_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _filters = [
    DashboardDateFilter.today,
    DashboardDateFilter.thisWeek,
    DashboardDateFilter.thisMonth,
  ];

  static String _filterLabel(DashboardDateFilter f) => switch (f) {
        DashboardDateFilter.today => AppStrings.filterToday,
        DashboardDateFilter.thisWeek => AppStrings.filterWeek,
        DashboardDateFilter.thisMonth || DashboardDateFilter.custom => AppStrings.filterMonth,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final notifier = ref.read(dashboardControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              const Padding(padding: AppSpacing.paddingGutter, child: DashboardHeader()),
              AppSpacing.gapLg,
              Padding(
                padding: AppSpacing.paddingGutter,
                child: PillTabs<DashboardDateFilter>(
                  values: _filters,
                  labelOf: _filterLabel,
                  selected: state.filter == DashboardDateFilter.custom ? DashboardDateFilter.thisMonth : state.filter,
                  onChanged: notifier.setFilter,
                ),
              ),
              AppSpacing.gapLg,
              if (state.errorMessage != null)
                _ErrorBody(message: state.errorMessage!)
              else if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xxxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _DashboardBody(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardState state;

  const _DashboardBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final expense = state.expenseAnalytics;
    final todo = state.todoAnalytics;
    final health = state.healthAnalytics;
    final insights = [
      if (expense.warningMessage != null)
        SmartInsight(id: 'expense-warning', message: expense.warningMessage!, type: InsightType.warning),
      ...state.insights,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Hero ──
        Padding(
          padding: AppSpacing.paddingGutter,
          child: HeroSummaryCard(
            title: AppStrings.totalSpent,
            amount: AppFormatters.currency(expense.totalSpent),
            badge: '${AppFormatters.currency(expense.averageDaily)} ${AppStrings.avgPerDay}',
            badgeIcon: Icons.show_chart_rounded,
            stats: [
              HeroStat(
                icon: Icons.savings_outlined,
                iconColor: AppColors.success,
                value: AppFormatters.currency(expense.possibleSavings),
                label: AppStrings.possibleSavings,
              ),
              HeroStat(
                icon: Icons.arrow_upward_rounded,
                iconColor: AppColors.error,
                value: AppFormatters.currency(expense.highestDayAmount),
                label: expense.highestDay == null
                    ? AppStrings.highestDay
                    : '${AppStrings.highestDay} · ${AppFormatters.dayMonth(expense.highestDay!)}',
              ),
            ],
          ),
        ),
        AppSpacing.gapLg,

        // ── Your day ──
        const Padding(padding: AppSpacing.paddingGutter, child: SectionHeader(title: AppStrings.yourDay)),
        AppSpacing.gapMd,
        _HorizontalStrip(
          height: AppSpacing.glanceStripHeight,
          children: [
            GlanceCard(
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.chartBlue,
              label: AppStrings.todosLabel,
              value: '${todo.completedTasks}/${todo.totalTasks}',
              caption: '${todo.completionPercentage.toStringAsFixed(0)}% ${AppStrings.tasksDone.toLowerCase()}',
              onTap: () => context.go('/todos'),
            ),
            GlanceCard(
              icon: Icons.local_fire_department_outlined,
              color: AppColors.chartOrange,
              label: AppStrings.streakLabel,
              value: '${todo.currentStreak} ${AppStrings.days}',
              caption: '${AppStrings.bestStreakSuffix} ${todo.bestStreak} ${AppStrings.days}',
            ),
            GlanceCard(
              icon: Icons.water_drop_outlined,
              color: AppColors.chartTeal,
              label: AppStrings.hydration,
              value: '${health.hydrationPercentage.toStringAsFixed(0)}%',
              caption: health.hydrationPercentage >= 100
                  ? AppStrings.hydrationGoalReached
                  : AppStrings.hydrationKeepGoing,
              onTap: () => context.go('/health/hydration'),
            ),
            GlanceCard(
              icon: Icons.nights_stay_outlined,
              color: AppColors.chartOrchid,
              label: AppStrings.sleep,
              value: health.lastNightSleep != null ? AppFormatters.duration(health.lastNightSleep!) : AppStrings.noData,
              caption: AppStrings.lastNight,
              onTap: () => context.go('/health/sleep'),
            ),
          ],
        ),
        AppSpacing.gapLg,

        // ── Spending trend ──
        Padding(padding: AppSpacing.paddingGutter, child: SpendingChartCard(analytics: expense)),

        // ── Insights ──
        if (insights.isNotEmpty) ...[
          AppSpacing.gapLg,
          const Padding(padding: AppSpacing.paddingGutter, child: SectionHeader(title: AppStrings.insights)),
          AppSpacing.gapMd,
          _HorizontalStrip(
            height: AppSpacing.insightStripHeight,
            children: [for (final i in insights) InsightCard(insight: i)],
          ),
        ],
        AppSpacing.gapLg,

        // ── Activity ──
        const Padding(padding: AppSpacing.paddingGutter, child: SectionHeader(title: AppStrings.recentActivity)),
        AppSpacing.gapMd,
        Padding(
          padding: AppSpacing.paddingGutter,
          child: ActivitySummaryRow(summary: state.activitySummary),
        ),
        AppSpacing.gapLg,
      ],
    );
  }
}

/// Horizontally scrolling row of fixed-height cards, aligned to the gutter.
class _HorizontalStrip extends StatelessWidget {
  final double height;
  final List<Widget> children;

  const _HorizontalStrip({required this.height, required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.paddingGutter,
        itemCount: children.length,
        separatorBuilder: (_, _) => AppSpacing.hGapSm,
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;

  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: AppSpacing.xxl, color: theme.colorScheme.error),
          AppSpacing.gapMd,
          Text(AppStrings.dashboardLoadFailed, style: theme.textTheme.titleMedium),
          Text(message, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
