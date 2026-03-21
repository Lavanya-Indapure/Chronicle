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
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null) {
                // Confirm if editing (simplification: always confirm for now as per prompt)
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    title: const Text('Confirm Budget Change'),
                    content: const Text('Are you sure you want to update your budget?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.pop(confirmCtx, true), child: const Text('Yes')),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref.read(expenseControllerProvider.notifier).setBudget(
                        amount: amount,
                        type: type,
                        startDate: DateTime.now(),
                      );
                  if (mounted) Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Set'),
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
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Quick way to set budgets
              _showBudgetOptions();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(expenseControllerProvider.notifier).loadAllData(),
        child: state.isLoading && state.expenses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Debt Summary Row
                  Row(
                    children: [
                      Expanded(
                        child: _DebtCard(
                          title: 'You Owe',
                          amount: state.youOwe,
                          color: Colors.red,
                          icon: Icons.unarchive_outlined,
                        ),
                      ),
                      AppSpacing.gapMd,
                      Expanded(
                        child: _DebtCard(
                          title: 'Others Owe',
                          amount: state.othersOweYou,
                          color: Colors.green,
                          icon: Icons.archive_outlined,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapLg,

                  // Budget Summaries
                  _BudgetCard(
                    title: 'Weekly Budget',
                    budget: state.currentWeeklyBudget,
                    spent: _calculateSpentForPeriod(state.expenses, isWeekly: true),
                    color: Colors.blue,
                    onSet: () => _showSetBudget(context, BudgetType.weekly),
                  ),
                  AppSpacing.gapMd,
                  _BudgetCard(
                    title: 'Monthly Budget',
                    budget: state.currentMonthlyBudget,
                    spent: _calculateSpentForPeriod(state.expenses, isWeekly: false),
                    color: Colors.purple,
                    onSet: () => _showSetBudget(context, BudgetType.monthly),
                  ),
                  AppSpacing.gapLg,

                  // Insights Card
                  if (state.unnecessarySpent > 0) ...[
                    _InsightsCard(unnecessarySpent: state.unnecessarySpent),
                    AppSpacing.gapLg,
                  ],

                  // Expenses List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Expenses', style: theme.textTheme.titleMedium),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const ExpenseHistoryScreen()),
                        ),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,

                  if (state.expenses.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('No expenses logged yet.'),
                    ))
                  else
                    ...state.expenses.map((e) => _ExpenseTile(expense: e)),
                  
                  AppSpacing.gapLg,

                  // Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending Debts', style: theme.textTheme.titleMedium),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => const TransactionHistoryScreen()),
                            ),
                            child: const Text('View All'),
                          ),
                          TextButton(
                            onPressed: () => _showAddTransaction(context),
                            child: const Text('Add Debt'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,

                  if (state.transactions.where((t) => t.status == TransactionStatus.pending).isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('All settled! No pending debts.'),
                    ))
                  else
                    ...state.transactions
                        .where((t) => t.status == TransactionStatus.pending)
                        .map((t) => _TransactionTile(
                              transaction: t,
                              onSettle: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm Settlement'),
                                    content: Text('Are you sure you want to mark the debt from ${t.personName} as settled?'),
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
                  
                  AppSpacing.gapXl, // Bottom padding
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpense(context),
        child: const Icon(Icons.add),
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
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('Set Weekly Budget'),
              onTap: () {
                Navigator.pop(ctx);
                _showSetBudget(context, BudgetType.weekly);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Set Monthly Budget'),
              onTap: () {
                Navigator.pop(ctx);
                _showSetBudget(context, BudgetType.monthly);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _DebtCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            AppSpacing.gapSm,
            Text(title, style: theme.textTheme.labelMedium?.copyWith(color: color)),
            AppSpacing.gapXs,
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String title;
  final double budget;
  final double spent;
  final Color color;
  final VoidCallback onSet;

  const _BudgetCard({
    required this.title,
    required this.budget,
    required this.spent,
    required this.color,
    required this.onSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > budget && budget > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: onSet,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget > 0 ? '${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}' : 'No budget set',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOver ? Colors.red : null,
                  ),
                ),
                if (budget > 0)
                  Text('${(progress * 100).toStringAsFixed(0)}%', style: theme.textTheme.bodyMedium),
              ],
            ),
            AppSpacing.gapMd,
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.red : color),
              ),
            ),
            if (isOver) ...[
              AppSpacing.gapSm,
              Text(
                'Over budget by ${(spent - budget).toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final double unnecessarySpent;

  const _InsightsCard({required this.unnecessarySpent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Savings Insight', style: theme.textTheme.titleSmall?.copyWith(color: Colors.amber.shade900)),
                Text(
                  'You could have saved ₹${unnecessarySpent.toStringAsFixed(0)} this period!',
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

class _ExpenseTile extends StatelessWidget {
  final Expense expense;

  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (expense.isNecessary ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
        child: Icon(
          expense.isNecessary ? Icons.check_circle_outline : Icons.shopping_bag_outlined,
          color: expense.isNecessary ? Colors.blue : Colors.orange,
        ),
      ),
      title: Text(expense.description ?? expense.category?.name ?? 'Expense'),
      subtitle: Text(
        '${expense.expenseDate.toString().split(' ').first}${expense.category != null && expense.description != null ? ' • ${expense.category!.name}' : ''}',
      ),
      trailing: Text(
        '₹${expense.amount.toStringAsFixed(0)}',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onSettle;

  const _TransactionTile({required this.transaction, required this.onSettle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLend = transaction.type == TransactionType.LEND;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (isLend ? Colors.green : Colors.red).withValues(alpha: 0.1),
        child: Icon(
          isLend ? Icons.arrow_upward : Icons.arrow_downward,
          color: isLend ? Colors.green : Colors.red,
        ),
      ),
      title: Text(transaction.personName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transaction.reason != null) Text(transaction.reason!),
          Text(transaction.date.toString().split(' ').first, style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${transaction.amount.toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isLend ? Colors.green : Colors.red,
            ),
          ),
          AppSpacing.gapSm,
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
            onPressed: onSettle,
            tooltip: 'Settle',
          ),
        ],
      ),
    );
  }
}
