import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/dashboard/domain/models/dashboard_models.dart';

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              AppSpacing.gapMd,
              Text('Failed to load dashboard', style: theme.textTheme.titleMedium),
              Text(state.errorMessage!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<DashboardDateFilter>(
              value: state.filter,
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, size: 20),
              dropdownColor: theme.colorScheme.surfaceContainer,
              items: const [
                DropdownMenuItem(value: DashboardDateFilter.today, child: Text("Today")),
                DropdownMenuItem(value: DashboardDateFilter.thisWeek, child: Text("This Week")),
                DropdownMenuItem(value: DashboardDateFilter.thisMonth, child: Text("This Month")),
              ],
              onChanged: (val) {
                if (val != null) {
                  notifier.setFilter(val);
                }
              },
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => notifier.setFilter(state.filter),
              child: ListView(
                padding: AppSpacing.paddingScreen,
                children: [
                   // Smart Insights Carousel
                  if (state.insights.isNotEmpty)
                    _InsightsCarousel(insights: state.insights),
                  
                  if (state.insights.isNotEmpty) AppSpacing.gapLg,

                  // 1. Hero: Expenses
                  _ExpenseAnalyticsCard(analytics: state.expenseAnalytics),

                  AppSpacing.gapLg,

                  // 2. Todos & Streaks
                  _TodoAnalyticsCard(analytics: state.todoAnalytics),

                  AppSpacing.gapLg,

                  // 3. Health & Hydration
                  Row(
                    children: [
                      Expanded(
                        child: _HealthMiniCard(
                          icon: Icons.water_drop,
                          title: "Hydration",
                          value: "${state.healthAnalytics.hydrationPercentage.toStringAsFixed(0)}%",
                          subtitle: state.healthAnalytics.hydrationPercentage >= 100 ? "Goal Reached!" : "Keep drinking!",
                          color: Colors.blue,
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: _HealthMiniCard(
                          icon: Icons.nights_stay,
                          title: "Sleep",
                          value: state.healthAnalytics.lastNightSleep != null 
                              ? "${state.healthAnalytics.lastNightSleep!.inHours}h ${state.healthAnalytics.lastNightSleep!.inMinutes.remainder(60)}m"
                              : "No data",
                          subtitle: "Last night",
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),

                  AppSpacing.gapLg,

                  // 4. Activity Summary
                  Text("Recent Activity", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  AppSpacing.gapSm,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActivityStat(icon: Icons.lightbulb, count: state.activitySummary.newLearnings, label: "Learned"),
                      _ActivityStat(icon: Icons.place, count: state.activitySummary.placesVisited, label: "Places"),
                      _ActivityStat(icon: Icons.mood, count: state.activitySummary.moodsLogged, label: "Moods"),
                    ],
                  ),

                  AppSpacing.gapXl,
                  AppSpacing.gapXl,
                ],
              ),
            ),
       // Floating action for quick adds
       floatingActionButton: FloatingActionButton.extended(
         onPressed: () {
           // Basic quick action - navigate to Expenses for instance
           context.go('/expenses');
         },
         icon: const Icon(Icons.add),
         label: const Text('New Entry'),
       ),
    );
  }
}

class _InsightsCarousel extends StatelessWidget {
  final List<SmartInsight> insights;
  const _InsightsCarousel({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 80,
      child: PageView.builder(
        itemCount: insights.length,
        itemBuilder: (context, index) {
          final insight = insights[index];
          final color = insight.type == InsightType.positive 
              ? Colors.green 
              : insight.type == InsightType.warning ? Colors.orange : theme.colorScheme.primary;
              
          return Card(
            color: color.withOpacity(0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(
                    insight.type == InsightType.positive ? Icons.star : Icons.info_outline,
                    color: color,
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(
                      insight.message,
                      style: theme.textTheme.bodyMedium?.copyWith(color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExpenseAnalyticsCard extends StatelessWidget {
  final ExpenseAnalytics analytics;
  const _ExpenseAnalyticsCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Expenses", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (analytics.warningMessage != null)
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              ],
            ),
            AppSpacing.gapSm,
            Text(
              currencyFormat.format(analytics.totalSpent),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              "Total spent • Avg ${currencyFormat.format(analytics.averageDaily)}/day",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            
            if (analytics.warningMessage != null) ...[
              AppSpacing.gapMd,
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analytics.warningMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (analytics.chartData.isNotEmpty) ...[
              AppSpacing.gapLg,
              SizedBox(
                height: 150,
                child: _ExpenseLineChart(chartData: analytics.chartData),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _ExpenseLineChart extends StatelessWidget {
  final Map<String, double> chartData;

  const _ExpenseLineChart({required this.chartData});

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    
    // Convert to spots
    final sortedKeys = chartData.keys.toList()..sort();
    final spots = <FlSpot>[];
    double maxAmount = 0;
    
    for (int i = 0; i < sortedKeys.length; i++) {
      final amount = chartData[sortedKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), amount));
      if (amount > maxAmount) maxAmount = amount;
    }

    // Determine interval for Y axis to try keeping it clean
    final interval = maxAmount > 0 ? (maxAmount / 4) : 100.0;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval > 0 ? interval : null,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (sortedKeys.length / 5).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  final dateStr = sortedKeys[value.toInt()];
                  final date = DateTime.parse(dateStr);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sortedKeys.length - 1).toDouble(),
        minY: 0,
        maxY: maxAmount * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoAnalyticsCard extends StatelessWidget {
  final TodoAnalytics analytics;
  const _TodoAnalyticsCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tasks & Streaks", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.gapMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(label: "Completed", value: "${analytics.completedTasks}/${analytics.totalTasks}", color: Colors.blue),
                _StatColumn(label: "Current Streak", value: "${analytics.currentStreak} days", color: Colors.orange),
                _StatColumn(label: "Best Streak", value: "${analytics.bestStreak} days", color: Colors.deepPurple),
              ],
            ),
            AppSpacing.gapLg,
            // Simple visual progress bar for completion %
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: analytics.totalTasks == 0 ? 0 : analytics.completionPercentage / 100,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: Colors.blue,
              ),
            ),
            AppSpacing.gapSm,
            Center(
              child: Text(
                "${analytics.completionPercentage.toStringAsFixed(1)}% completion rate",
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _HealthMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _HealthMiniCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            AppSpacing.gapMd,
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            AppSpacing.gapXs,
            Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _ActivityStat({required this.icon, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
        ),
        AppSpacing.gapSm,
        Text(count.toString(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
