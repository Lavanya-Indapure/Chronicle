import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_constants.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/action_pill.dart';
import 'package:chronicle/core/widgets/circle_icon_button.dart';
import 'package:chronicle/core/widgets/hero_summary_card.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/screens/expense_history_screen.dart';
import 'package:chronicle/features/expenses/presentation/screens/transaction_history_screen.dart';
import 'package:chronicle/features/expenses/presentation/widgets/budget_card.dart';
import 'package:chronicle/features/expenses/presentation/widgets/budget_dialogs.dart';
import 'package:chronicle/features/expenses/presentation/widgets/category_breakdown_section.dart';
import 'package:chronicle/features/expenses/presentation/widgets/category_visuals.dart';
import 'package:chronicle/features/expenses/presentation/widgets/debt_list_tile.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_list_tile.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_sheets.dart';

enum _ExpenseTab { categories, budgets }

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  _ExpenseTab _tab = _ExpenseTab.categories;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(expenseControllerProvider.notifier).loadAllData());
  }

  void _refreshDashboard() => ref.read(dashboardControllerProvider.notifier).refresh();

  void _openPage(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _confirmSettle(Transaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.confirmSettlementTitle),
        content: Text('${AppStrings.confirmSettlementPrefix} ${t.personName} ${AppStrings.confirmSettlementSuffix}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.settle)),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(expenseControllerProvider.notifier).settleTransaction(t.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseControllerProvider);
    final breakdown = state.monthlyCategoryBreakdown;

    // Keep a category's colour identical in the donut, tiles and list rows.
    final rankByCategory = {for (var i = 0; i < breakdown.length; i++) breakdown[i].name: i};
    Color colorFor(String? category) =>
        CategoryVisuals.colorAt(rankByCategory[category] ?? (category?.hashCode ?? 0).abs());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(expenseControllerProvider.notifier).loadAllData(),
          child: state.isLoading && state.expenses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
                  children: [
                    _Header(
                      onSearch: () => _openPage(const ExpenseHistoryScreen()),
                      onBudgets: () => showBudgetOptionsSheet(context, ref),
                    ),
                    AppSpacing.gapLg,
                    HeroSummaryCard(
                      title: AppStrings.spentThisMonth,
                      amount: AppFormatters.currency(state.spentThisMonth),
                      badge: '${AppFormatters.currency(state.spentThisWeek)} ${AppStrings.thisWeek}',
                      badgeIcon: Icons.show_chart_rounded,
                      stats: [
                        HeroStat(
                          icon: Icons.arrow_upward_rounded,
                          iconColor: AppColors.error,
                          value: AppFormatters.currency(state.youOwe),
                          label: AppStrings.youOwe,
                        ),
                        HeroStat(
                          icon: Icons.arrow_downward_rounded,
                          iconColor: AppColors.success,
                          value: AppFormatters.currency(state.othersOweYou),
                          label: AppStrings.owedToYou,
                        ),
                      ],
                    ),
                    AppSpacing.gapMd,
                    _QuickActions(
                      onAddExpense: () => showAddExpenseSheet(context, ref, onSaved: _refreshDashboard),
                      onAddDebt: () => showAddTransactionSheet(context, ref),
                      onBudgets: () => showBudgetOptionsSheet(context, ref),
                    ),
                    AppSpacing.gapLg,
                    PillTabs<_ExpenseTab>(
                      values: _ExpenseTab.values,
                      labelOf: (t) => t == _ExpenseTab.categories ? AppStrings.categories : AppStrings.budgets,
                      selected: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                    AppSpacing.gapLg,
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _tab == _ExpenseTab.categories
                          ? CategoryBreakdownSection(
                              key: const ValueKey(_ExpenseTab.categories),
                              breakdown: breakdown,
                              total: state.spentThisMonth,
                            )
                          : _BudgetsSection(
                              key: const ValueKey(_ExpenseTab.budgets),
                              state: state,
                              onEdit: (type) => showSetBudgetDialog(context, ref, type),
                            ),
                    ),
                    if (state.unnecessarySpent > 0) ...[
                      AppSpacing.gapMd,
                      _SavingsInsight(amount: state.unnecessarySpent),
                    ],
                    AppSpacing.gapXl,
                    SectionHeader(
                      title: AppStrings.transactions,
                      trailing: TextButton(
                        onPressed: () => _openPage(const ExpenseHistoryScreen()),
                        child: const Text(AppStrings.seeAll),
                      ),
                    ),
                    AppSpacing.gapSm,
                    _RecentExpenses(expenses: state.expenses, colorFor: colorFor),
                    AppSpacing.gapXl,
                    SectionHeader(
                      title: AppStrings.pendingDebts,
                      trailing: TextButton(
                        onPressed: () => _openPage(const TransactionHistoryScreen()),
                        child: const Text(AppStrings.seeAll),
                      ),
                    ),
                    AppSpacing.gapSm,
                    _PendingDebts(transactions: state.pendingTransactions, onSettle: _confirmSettle),
                    AppSpacing.gapLg,
                  ],
                ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onBudgets;

  const _Header({required this.onSearch, required this.onBudgets});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(AppStrings.expensesLabel, style: Theme.of(context).textTheme.headlineMedium)),
        CircleIconButton(icon: Icons.search_rounded, tooltip: AppStrings.search, onPressed: onSearch),
        AppSpacing.hGapSm,
        CircleIconButton(icon: Icons.tune_rounded, tooltip: AppStrings.budgets, onPressed: onBudgets),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onAddDebt;
  final VoidCallback onBudgets;

  const _QuickActions({required this.onAddExpense, required this.onAddDebt, required this.onBudgets});

  @override
  Widget build(BuildContext context) {
    // Scrolls horizontally on narrow screens instead of overflowing.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          ActionPill(icon: Icons.add_rounded, iconColor: AppColors.success, label: AppStrings.addExpense, onTap: onAddExpense),
          AppSpacing.hGapSm,
          ActionPill(icon: Icons.add_rounded, iconColor: AppColors.error, label: AppStrings.addDebt, onTap: onAddDebt),
          AppSpacing.hGapSm,
          ActionPill(icon: Icons.tune_rounded, iconColor: AppColors.info, label: AppStrings.budgets, onTap: onBudgets),
        ],
      ),
    );
  }
}

class _BudgetsSection extends StatelessWidget {
  final ExpenseState state;
  final ValueChanged<BudgetType> onEdit;

  const _BudgetsSection({super.key, required this.state, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BudgetCard(
          title: AppStrings.weeklyBudget,
          budget: state.currentWeeklyBudget,
          spent: state.spentThisWeek,
          color: AppColors.chartBlue,
          onEdit: () => onEdit(BudgetType.weekly),
        ),
        AppSpacing.gapSm,
        BudgetCard(
          title: AppStrings.monthlyBudget,
          budget: state.currentMonthlyBudget,
          spent: state.spentThisMonth,
          color: AppColors.chartOrchid,
          onEdit: () => onEdit(BudgetType.monthly),
        ),
      ],
    );
  }
}

class _SavingsInsight extends StatelessWidget {
  final double amount;

  const _SavingsInsight({required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const IconBadge(icon: Icons.lightbulb_outline_rounded, color: AppColors.chartLemon),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.savingsInsightTitle, style: theme.textTheme.titleSmall),
                Text(
                  '${AppStrings.savingsInsightPrefix} ${AppFormatters.currency(amount)} ${AppStrings.savingsInsightSuffix}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Latest expenses grouped under "Today · 15 Nov" style day labels.
class _RecentExpenses extends StatelessWidget {
  final List<Expense> expenses;
  final Color Function(String? category) colorFor;

  const _RecentExpenses({required this.expenses, required this.colorFor});

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    final prefix = switch (diff) {
      0 => '${AppStrings.today} · ',
      1 => '${AppStrings.yesterday} · ',
      _ => '',
    };
    return '$prefix${AppFormatters.dayMonth(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (expenses.isEmpty) {
      return SurfaceCard(
        child: Center(child: Text(AppStrings.noExpensesYet, style: theme.textTheme.bodyMedium)),
      );
    }

    final recent = ([...expenses]..sort((a, b) => b.expenseDate.compareTo(a.expenseDate)))
        .take(AppConstants.recentExpensesLimit);
    final children = <Widget>[];
    String? currentLabel;
    for (final e in recent) {
      final label = _dayLabel(e.expenseDate);
      if (label != currentLabel) {
        currentLabel = label;
        children.add(Padding(
          padding: EdgeInsets.only(top: children.isEmpty ? 0 : AppSpacing.md, bottom: AppSpacing.sm),
          child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ));
      } else {
        children.add(AppSpacing.gapSm);
      }
      children.add(ExpenseListTile(expense: e, color: colorFor(e.category?.name)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _PendingDebts extends StatelessWidget {
  final List<Transaction> transactions;
  final ValueChanged<Transaction> onSettle;

  const _PendingDebts({required this.transactions, required this.onSettle});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return SurfaceCard(
        child: Center(child: Text(AppStrings.allSettled, style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
    return Column(
      children: [
        for (final t in transactions) ...[
          DebtListTile(transaction: t, onSettle: () => onSettle(t)),
          if (t != transactions.last) AppSpacing.gapSm,
        ],
      ],
    );
  }
}
