import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_constants.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/circle_icon_button.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/expense_navigation.dart';
import 'package:chronicle/features/expenses/presentation/screens/expense_history_screen.dart';
import 'package:chronicle/features/expenses/presentation/screens/transaction_history_screen.dart';
import 'package:chronicle/features/expenses/presentation/widgets/budget_dialogs.dart';
import 'package:chronicle/features/expenses/presentation/widgets/category_summary_card.dart';
import 'package:chronicle/features/expenses/presentation/widgets/category_visuals.dart';
import 'package:chronicle/features/expenses/presentation/widgets/debts_summary_row.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_list_tile.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_sheets.dart';
import 'package:chronicle/features/expenses/presentation/widgets/month_summary_card.dart';
import 'package:chronicle/features/expenses/presentation/widgets/month_switcher.dart';

/// Expenses home, top to bottom: month switcher → month summary (with
/// budgets) → where it went → transactions → debts.
/// Adding happens from the nav bar's + (Quick Add).
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  ExpenseController get _controller => ref.read(expenseControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _controller.loadAllData());
  }

  void _refreshDashboard() => ref.read(dashboardControllerProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseControllerProvider);

    ref.listen(expenseControllerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    final breakdown = state.viewMonthBreakdown;
    // Keep a category's colour identical in the ring, legend and list rows.
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
                    ),
                    AppSpacing.gapMd,
                    MonthSwitcher(
                      month: state.viewMonth,
                      firstMonth: state.earliestMonth,
                      lastMonth: state.latestMonth,
                      onMonthSelected: _controller.showMonth,
                    ),
                    AppSpacing.gapMd,
                    MonthSummaryCard(
                      state: state,
                      onManageBudgets: () => showBudgetOptionsSheet(context, ref),
                    ),
                    if (breakdown.isNotEmpty) ...[
                      AppSpacing.gapMd,
                      CategorySummaryCard(breakdown: breakdown, onSeeAll: () => openAllCategories(context)),
                    ],
                    AppSpacing.gapLg,
                    SectionHeader(
                      title: AppStrings.transactions,
                      compact: true,
                      trailing: TextButton(
                        onPressed: () => openMonthHistory(context, ref),
                        child: const Text(AppStrings.seeAll),
                      ),
                    ),
                    AppSpacing.gapXs,
                    _MonthExpenses(
                      expenses: state.viewMonthExpenses,
                      colorFor: colorFor,
                      onTap: (e) => showExpenseDetails(context, ref, e, color: colorFor(e.categoryId), onChanged: _refreshDashboard),
                      onDelete: (e) async {
                        if (await _controller.deleteExpense(e.id)) _refreshDashboard();
                      },
                      onSeeAll: () => openMonthHistory(context, ref),
                    ),
                    AppSpacing.gapLg,
                    DebtsSummaryRow(
                      youOwe: state.youOwe,
                      owedToYou: state.othersOweYou,
                      pendingCount: state.pendingTransactions.length,
                      onTap: () => Navigator.push(
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

  const _Header({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(AppStrings.expensesLabel, style: Theme.of(context).textTheme.headlineMedium)),
        CircleIconButton(icon: Icons.search_rounded, tooltip: AppStrings.search, onPressed: onSearch),
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
