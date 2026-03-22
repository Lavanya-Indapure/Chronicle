import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/widgets/transaction_filter_sheet.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/presentation/widgets/transaction_list_tile.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseControllerProvider);
    final theme = Theme.of(context);
    final transactions = state.filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: state.transactionFilters != const TransactionFilters() ? theme.colorScheme.primary : null,
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
              hintText: 'Search people or reasons...',
              leading: const Icon(Icons.search_rounded),
              onChanged: (value) => ref.read(expenseControllerProvider.notifier).setSearchQuery(value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.md)),
            ),
          ),
          if (state.transactionFilters != const TransactionFilters())
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.md),
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('Reset Filters'),
                    onPressed: () => ref.read(expenseControllerProvider.notifier).clearFilters(),
                    avatar: const Icon(Icons.refresh_rounded, size: 14),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                        AppSpacing.gapMd,
                        Text(
                          state.transactionSearchQuery.isEmpty && state.transactionFilters == const TransactionFilters()
                              ? 'No records found'
                              : 'No matches found',
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
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return TransactionListTile(
                        transaction: t,
                        showSettleButton: false,
                        onSettle: t.status == TransactionStatus.settled
                          ? null
                          : () => _showSettleConfirmation(context, ref, t),
                        onTap: t.status == TransactionStatus.settled
                          ? null
                          : () => _showSettleConfirmation(context, ref, t),
                      );
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
      builder: (ctx) => const TransactionFilterSheet(),
    );
  }

  void _showSettleConfirmation(BuildContext context, WidgetRef ref, Transaction t) async {
    if (t.status == TransactionStatus.settled) return;

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
  }
}
