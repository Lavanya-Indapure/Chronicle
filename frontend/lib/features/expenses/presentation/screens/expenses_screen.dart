import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/widgets/add_expense_sheet.dart';
import 'package:chronicle/features/expenses/presentation/widgets/add_transaction_sheet.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/presentation/screens/transaction_history_screen.dart';
import 'package:chronicle/features/expenses/presentation/screens/expense_history_screen.dart';

import 'package:chronicle/features/expenses/presentation/widgets/debt_card.dart';
import 'package:chronicle/features/expenses/presentation/widgets/budget_card.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_insights_card.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_list_tile.dart';
import 'package:chronicle/features/expenses/presentation/widgets/transaction_list_tile.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(expenseControllerProvider.notifier).loadAllData());
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddTransactionSheet(
        onSubmit: ({required personName, required amount, required type, reason, required date}) =>
            ref.read(expenseControllerProvider.notifier).addTransaction(
                  personName: personName,
                  amount: amount,
                  type: type,
                  reason: reason,
                  date: date,
                ),
      ),
    );
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddExpenseSheet(
        onSubmit: ({required amount, description, categoryId, required isNecessary, required date}) =>
            ref.read(expenseControllerProvider.notifier).addExpense(
                  amount: amount,
                  description: description,
                  categoryId: categoryId,
                  isNecessary: isNecessary,
                  date: date,
                ),
      ),
    );
  }

  void _showSetBudget(BuildContext context, BudgetType type) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set ${type.label} Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Budget Amount',
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
            hintText: 'Enter amount...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null) {
                await showDialog<bool>(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    title: const Text('Confirm Budget Change'),
                    content: const Text('Update your goal for this period?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.pop(confirmCtx, true), child: const Text('Yes')),
                    ],
                  ),
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Set Budget'),
          ),
        ],
      ),
    );
  }

  double _calculateSpentForPeriod(List<Expense> expenses, {required bool isWeekly}) {
    final now = DateTime.now();
    if (isWeekly) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      return expenses
          .where((e) => e.expenseDate.isAfter(weekStartDay.subtract(const Duration(seconds: 1))))
          .fold(0.0, (sum, e) => sum + e.amount);
    } else {
      final monthStart = DateTime(now.year, now.month, 1);
      return expenses
          .where((e) => e.expenseDate.isAfter(monthStart.subtract(const Duration(seconds: 1))))
          .fold(0.0, (sum, e) => sum + e.amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showBudgetOptions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(expenseControllerProvider.notifier).loadAllData(),
        child: state.isLoading && state.expenses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: AppSpacing.paddingScreen,
                children: [
                  // Debt Summary
                  Row(
                    children: [
                      Expanded(
                        child: DebtCard(
                          title: 'You Owe',
                          amount: state.youOwe,
                          color: theme.colorScheme.error,
                          icon: Icons.upload_rounded,
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: DebtCard(
                          title: 'Others Owe',
                          amount: state.othersOweYou,
                          color: Colors.green,
                          icon: Icons.download_rounded,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapLg,

                  // Budget Summaries
                  BudgetCard(
                    title: 'Weekly Budget',
                    budget: state.currentWeeklyBudget,
                    spent: _calculateSpentForPeriod(state.expenses, isWeekly: true),
                    color: theme.colorScheme.primary,
                    onSet: () => _showSetBudget(context, BudgetType.weekly),
                  ),
                  AppSpacing.gapMd,
                  BudgetCard(
                    title: 'Monthly Budget',
                    budget: state.currentMonthlyBudget,
                    spent: _calculateSpentForPeriod(state.expenses, isWeekly: false),
                    color: Colors.indigo,
                    onSet: () => _showSetBudget(context, BudgetType.monthly),
                  ),
                  AppSpacing.gapLg,

                  // Insights
                  if (state.unnecessarySpent > 0) ...[
                    ExpenseInsightsCard(unnecessarySpent: state.unnecessarySpent),
                    AppSpacing.gapLg,
                  ],

                  // Expenses List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Expenses', 
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        )
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const ExpenseHistoryScreen()),
                        ),
                        child: Text(
                          'See All',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,

                  if (state.expenses.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No expenses logged yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ))
                  else
                    ...state.expenses.take(5).map((e) => ExpenseListTile(expense: e)),
                  
                  AppSpacing.gapLg,

                  // Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Debts', 
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        )
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => const TransactionHistoryScreen()),
                            ),
                            child: const Text('View All'),
                          ),
                          IconButton(
                            onPressed: () => _showAddTransaction(context),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,

                  if (state.transactions.where((t) => t.status == TransactionStatus.pending).isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'All settled! No pending debts.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ))
                  else
                    ...state.transactions
                        .where((t) => t.status == TransactionStatus.pending)
                        .take(5)
                        .map((t) => TransactionListTile(
                              transaction: t,
                              onSettle: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm Settlement'),
                                    content: Text('Mark debt from ${t.personName} as settled?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Settle')),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  ref.read(expenseControllerProvider.notifier).settleTransaction(t.id);
                                }
                              },
                            )),
                  
                  AppSpacing.gapXxl,
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpense(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Expense'),
        elevation: 4,
      ),
    );
  }

  void _showBudgetOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSpacing.gapMd,
            ListTile(
              leading: const Icon(Icons.calendar_view_week_rounded),
              title: const Text('Set Weekly Budget'),
              onTap: () {
                Navigator.pop(ctx);
                _showSetBudget(context, BudgetType.weekly);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('Set Monthly Budget'),
              onTap: () {
                Navigator.pop(ctx);
                _showSetBudget(context, BudgetType.monthly);
              },
            ),
            AppSpacing.gapMd,
          ],
        ),
      ),
    );
  }
}
