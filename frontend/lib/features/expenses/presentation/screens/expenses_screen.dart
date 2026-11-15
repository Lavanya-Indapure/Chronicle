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
import 'package:chronicle/core/widgets/pill_tabs.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/domain/models/category_spend.dart';
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
import 'package:chronicle/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_list_tile.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_sheets.dart';
import 'package:chronicle/features/expenses/presentation/widgets/month_switcher.dart';

enum _ExpenseTab { categories, budgets }

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  _ExpenseTab _tab = _ExpenseTab.categories;

  ExpenseController get _controller => ref.read(expenseControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _controller.loadAllData());
  }

  void _refreshDashboard() => ref.read(dashboardControllerProvider.notifier).refresh();

  /// Opens Expense History pre-filtered to the viewed month (and optionally
  /// one category); clears the filter again on return.
  Future<void> _openHistory({String? categoryId}) async {
    final state = ref.read(expenseControllerProvider);
    final month = state.viewMonth;
    _controller
      ..setExpenseSearchQuery('')
      ..setExpenseFilters(ExpenseFilters(
        categoryId: categoryId,
        startDate: month,
        endDate: DateTime(month.year, month.month + 1, 0),
      ));
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen()));
    if (mounted) _controller.clearExpenseFilters();
  }

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
    if (confirmed == true) await _controller.settleTransaction(t.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseControllerProvider);

    ref.listen(expenseControllerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    final breakdown = state.viewMonthBreakdown;
    // Keep a category's colour identical in the donut, tiles and list rows.
    final rankByCategory = {for (var i = 0; i < breakdown.length; i++) breakdown[i].categoryId: i};
    Color colorFor(String? categoryId) =>
        CategoryVisuals.colorAt(rankByCategory[categoryId] ?? (categoryId?.hashCode ?? 0).abs());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _controller.loadAllData,
          child: state.isLoading && state.expenses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.lg),
                  children: [
                    _Header(
                      onSearch: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen()),
                      ),
                      onBudgets: () => showBudgetOptionsSheet(context, ref),
                    ),
                    AppSpacing.gapMd,
                    MonthSwitcher(
                      month: state.viewMonth,
                      firstMonth: state.earliestMonth,
                      lastMonth: state.latestMonth,
                      onMonthSelected: _controller.showMonth,
                    ),
                    AppSpacing.gapMd,
                    _MonthSummary(state: state),
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
                              key: ValueKey(('categories', state.viewMonth)),
                              breakdown: breakdown,
                              total: state.viewMonthSpent,
                              month: state.viewMonth,
                              onCategoryTap: (CategorySpend c) => _openHistory(categoryId: c.categoryId),
                            )
                          : _BudgetsSection(
                              key: const ValueKey(_ExpenseTab.budgets),
                              state: state,
                              onEdit: (type) => showSetBudgetDialog(context, ref, type),
                            ),
                    ),
                    AppSpacing.gapXl,
                    SectionHeader(
                      title: AppStrings.transactions,
                      trailing: TextButton(onPressed: _openHistory, child: const Text(AppStrings.seeAll)),
                    ),
                    AppSpacing.gapSm,
                    _MonthExpenses(
                      expenses: state.viewMonthExpenses,
                      colorFor: colorFor,
                      onTap: (e) => showExpenseDetails(context, ref, e, color: colorFor(e.categoryId), onChanged: _refreshDashboard),
                      onDelete: (e) async {
                        if (await _controller.deleteExpense(e.id)) _refreshDashboard();
                      },
                      onSeeAll: _openHistory,
                    ),
                    AppSpacing.gapXl,
                    _DebtsSection(
                      state: state,
                      onSettle: _confirmSettle,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                      ),
                    ),
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

/// Lemon summary for the viewed month: total, change vs the previous month,
/// budget progress (current month only), daily average and non-essentials.
class _MonthSummary extends StatelessWidget {
  final ExpenseState state;

  const _MonthSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final spent = state.viewMonthSpent;
    final previous = state.previousMonthSpent;
    final prevMonth = DateTime(state.viewMonth.year, state.viewMonth.month - 1);

    String? badge;
    IconData? badgeIcon;
    if (previous > 0) {
      final change = (spent - previous) / previous;
      final pct = (change.abs() * 100).round();
      badgeIcon = pct == 0 ? Icons.trending_flat_rounded : (change > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded);
      badge = pct == 0
          ? '${AppStrings.sameAsLastMonth} ${AppFormatters.shortMonth(prevMonth)}'
          : '$pct% ${AppStrings.vs} ${AppFormatters.shortMonth(prevMonth)}';
    }

    final budget = state.currentMonthlyBudget;
    return HeroSummaryCard(
      title: '${AppStrings.spentIn} ${AppFormatters.monthName(state.viewMonth)}',
      amount: AppFormatters.currency(spent),
      badge: badge,
      badgeIcon: badgeIcon,
      footer: state.isViewingCurrentMonth && budget > 0 ? _BudgetProgress(spent: spent, budget: budget) : null,
      stats: [
        HeroStat(
          icon: Icons.calendar_today_rounded,
          iconColor: AppColors.chartBlue,
          value: AppFormatters.currency(state.viewMonthDailyAverage),
          label: AppStrings.dailyAvg,
        ),
        HeroStat(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warning,
          value: AppFormatters.currency(state.viewMonthNonEssential),
          label: AppStrings.nonEssentialSpend,
        ),
      ],
    );
  }
}

/// Budget bar drawn on the lemon card.
class _BudgetProgress extends StatelessWidget {
  final double spent;
  final double budget;

  const _BudgetProgress({required this.spent, required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;
    final over = spent > budget;
    final label = over
        ? '${AppStrings.budgetOverPrefix} ${AppFormatters.currency(spent - budget)}'
        : '${AppFormatters.currency(budget - spent)} ${AppStrings.budgetLeftSuffix} ${AppFormatters.currency(budget)}';

    return Column(
      children: [
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusPill,
          child: LinearProgressIndicator(
            value: (spent / budget).clamp(0.0, 1.0),
            minHeight: AppSpacing.progressBarHeight,
            color: over ? AppColors.error : ink,
            backgroundColor: ink.withValues(alpha: 0.12),
          ),
        ),
        AppSpacing.gapXs,
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: over ? AppColors.error : ink)),
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

/// The viewed month's expenses grouped by day ("Today · 15 Nov ..... ₹1,240").
/// Tap a row for details; swipe left to delete.
class _MonthExpenses extends StatelessWidget {
  final List<Expense> expenses;
  final Color Function(String? categoryId) colorFor;
  final ValueChanged<Expense> onTap;
  final ValueChanged<Expense> onDelete;
  final VoidCallback onSeeAll;

  const _MonthExpenses({
    required this.expenses,
    required this.colorFor,
    required this.onTap,
    required this.onDelete,
    required this.onSeeAll,
  });

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dayLabel(DateTime day) {
    final today = _day(DateTime.now());
    final prefix = switch (today.difference(day).inDays) {
      0 => '${AppStrings.today} · ',
      1 => '${AppStrings.yesterday} · ',
      _ => '',
    };
    return '$prefix${AppFormatters.dayMonth(day)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (expenses.isEmpty) {
      return SurfaceCard(
        child: Center(child: Text(AppStrings.noExpensesThisMonth, style: theme.textTheme.bodyMedium)),
      );
    }

    final shown = expenses.take(AppConstants.recentExpensesLimit).toList();
    // Day totals use every expense that day, not just the rows shown.
    final dayTotals = <DateTime, double>{};
    for (final e in expenses) {
      dayTotals.update(_day(e.expenseDate), (v) => v + e.amount, ifAbsent: () => e.amount);
    }

    final children = <Widget>[];
    DateTime? currentDay;
    for (final e in shown) {
      final day = _day(e.expenseDate);
      if (day != currentDay) {
        currentDay = day;
        children.add(Padding(
          padding: EdgeInsets.only(top: children.isEmpty ? 0 : AppSpacing.md, bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _dayLabel(day),
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              Text(AppFormatters.currency(dayTotals[day]!), style: theme.textTheme.labelMedium),
            ],
          ),
        ));
      } else {
        children.add(AppSpacing.gapSm);
      }
      children.add(Dismissible(
        key: ValueKey(e.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => confirmDeleteExpense(context),
        onDismissed: (_) => onDelete(e),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(color: AppColors.error, borderRadius: AppSpacing.borderRadiusXl),
          child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onError),
        ),
        child: ExpenseListTile(expense: e, color: colorFor(e.categoryId), onTap: () => onTap(e)),
      ));
    }

    final hidden = expenses.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        if (hidden > 0) ...[
          AppSpacing.gapSm,
          TextButton(onPressed: onSeeAll, child: Text('${AppStrings.seeAll} (${expenses.length})')),
        ],
      ],
    );
  }
}

/// Owe / owed totals and the pending debts list.
class _DebtsSection extends StatelessWidget {
  final ExpenseState state;
  final ValueChanged<Transaction> onSettle;
  final VoidCallback onSeeAll;

  const _DebtsSection({required this.state, required this.onSettle, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = state.pendingTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppStrings.debts,
          trailing: TextButton(onPressed: onSeeAll, child: const Text(AppStrings.seeAll)),
        ),
        AppSpacing.gapSm,
        Row(
          children: [
            Expanded(child: _DebtTotal(label: AppStrings.youOwe, amount: state.youOwe, color: AppColors.error)),
            AppSpacing.hGapSm,
            Expanded(child: _DebtTotal(label: AppStrings.owedToYou, amount: state.othersOweYou, color: AppColors.success)),
          ],
        ),
        AppSpacing.gapSm,
        if (pending.isEmpty)
          SurfaceCard(child: Center(child: Text(AppStrings.allSettled, style: theme.textTheme.bodyMedium)))
        else
          for (final t in pending) ...[
            DebtListTile(transaction: t, onSettle: () => onSettle(t)),
            if (t != pending.last) AppSpacing.gapSm,
          ],
      ],
    );
  }
}

class _DebtTotal extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _DebtTotal({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          AppSpacing.gapXs,
          Text(AppFormatters.currency(amount), style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
