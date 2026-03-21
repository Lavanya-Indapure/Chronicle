import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_filter_sheet.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';

class ExpenseHistoryScreen extends ConsumerWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseControllerProvider);
    final theme = Theme.of(context);
    final expenses = state.filteredExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: state.expenseFilters != const ExpenseFilters() || state.expenseSorting != ExpenseSorting.latest
                  ? theme.colorScheme.primary
                  : null,
            ),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SearchBar(
              hintText: 'Search category or description...',
              leading: const Icon(Icons.search),
              onChanged: (value) => ref.read(expenseControllerProvider.notifier).setExpenseSearchQuery(value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
            ),
          ),
          if (state.expenseFilters != const ExpenseFilters() || state.expenseSorting != ExpenseSorting.latest)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('Clear Filters'),
                    onPressed: () => ref.read(expenseControllerProvider.notifier).clearExpenseFilters(),
                    avatar: const Icon(Icons.close, size: 16),
                  ),
                  AppSpacing.gapSm,
                  if (state.expenseSorting != ExpenseSorting.latest)
                     Chip(
                      label: Text('Sort: ${state.expenseSorting.name}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: theme.disabledColor),
                        AppSpacing.gapMd,
                        Text(
                          state.expenseSearchQuery.isEmpty && state.expenseFilters == const ExpenseFilters()
                              ? 'No expenses yet'
                              : 'No matching expenses found',
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = expenses[index];
                      return _ExpenseHistoryTile(expense: e);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const ExpenseFilterSheet(),
    );
  }
}

class _ExpenseHistoryTile extends StatelessWidget {
  final Expense expense;

  const _ExpenseHistoryTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: CircleAvatar(
        backgroundColor: (expense.isNecessary ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
        child: Icon(
          expense.isNecessary ? Icons.check_circle_outline : Icons.shopping_bag_outlined,
          color: expense.isNecessary ? Colors.blue : Colors.orange,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(expense.description ?? expense.category?.name ?? 'Expense', style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(
            '₹${expense.amount.toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            '${expense.expenseDate.toString().split(' ').first}${expense.category != null && expense.description != null ? ' • ${expense.category!.name}' : ''}',
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          if (!expense.isNecessary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Unnecessary',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
