import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_filter_sheet.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_list_tile.dart';

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
              Icons.tune_rounded,
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
              hintText: 'Search expenses...',
              leading: const Icon(Icons.search_rounded),
              onChanged: (value) => ref.read(expenseControllerProvider.notifier).setExpenseSearchQuery(value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.md)),
            ),
          ),
          if (state.expenseFilters != const ExpenseFilters() || state.expenseSorting != ExpenseSorting.latest)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.md),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      label: const Text('Reset'),
                      onPressed: () => ref.read(expenseControllerProvider.notifier).clearExpenseFilters(),
                      avatar: const Icon(Icons.refresh_rounded, size: 14),
                      visualDensity: VisualDensity.compact,
                    ),
                    AppSpacing.hGapSm,
                    if (state.expenseSorting != ExpenseSorting.latest)
                       Chip(
                        label: Text('Sort: ${state.expenseSorting.name}'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                        AppSpacing.gapMd,
                        Text(
                          state.expenseSearchQuery.isEmpty && state.expenseFilters == const ExpenseFilters()
                              ? 'No records found'
                              : 'No matches for your filters',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      return ExpenseListTile(expense: expenses[index]);
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
