import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/widgets/transaction_filter_sheet.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';

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
              Icons.filter_list,
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
              hintText: 'Search person or reason...',
              leading: const Icon(Icons.search),
              onChanged: (value) => ref.read(expenseControllerProvider.notifier).setSearchQuery(value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
            ),
          ),
          if (state.transactionFilters != const TransactionFilters())
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('Clear Filters'),
                    onPressed: () => ref.read(expenseControllerProvider.notifier).clearFilters(),
                    avatar: const Icon(Icons.close, size: 16),
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
                        Icon(Icons.history_outlined, size: 64, color: theme.disabledColor),
                        AppSpacing.gapMd,
                        Text(
                          state.transactionSearchQuery.isEmpty && state.transactionFilters == const TransactionFilters()
                              ? 'No transactions yet'
                              : 'No matching transactions found',
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return _HistoryTile(
                        transaction: t,
                        onSettle: () => _showSettleConfirmation(context, ref, t),
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
  }
}

class _HistoryTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onSettle;

  const _HistoryTile({required this.transaction, required this.onSettle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLend = transaction.type == TransactionType.LEND;
    final isSettled = transaction.status == TransactionStatus.settled;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: CircleAvatar(
        backgroundColor: (isLend ? Colors.green : Colors.red).withValues(alpha: 0.1),
        child: Icon(
          isLend ? Icons.arrow_upward : Icons.arrow_downward,
          color: isLend ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(transaction.personName, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(
            '₹${transaction.amount.toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isLend ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transaction.reason != null) Text(transaction.reason!),
          Row(
            children: [
              Text(transaction.date.toString().split(' ').first, style: theme.textTheme.bodySmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSettled ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isSettled ? 'Settled' : 'Pending',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSettled ? Colors.blue : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: isSettled ? null : onSettle,
    );
  }
}
