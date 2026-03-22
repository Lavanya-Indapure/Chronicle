import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';

class TransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onSettle;
  final VoidCallback? onTap;
  final bool showSettleButton;

  const TransactionListTile({
    super.key,
    required this.transaction,
    this.onSettle,
    this.onTap,
    this.showSettleButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLend = transaction.type == TransactionType.lend;
    final color = isLend ? Colors.green : theme.colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs, top: 4, bottom: 4),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            isLend ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.personName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.reason != null && transaction.reason!.isNotEmpty)
              Text(
                transaction.reason!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            Text(
              '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${transaction.amount.toInt()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (!showSettleButton)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: transaction.status == TransactionStatus.settled 
                        ? Colors.blue.withValues(alpha: 0.1) 
                        : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.status == TransactionStatus.settled ? 'Settled' : 'Pending',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: transaction.status == TransactionStatus.settled ? Colors.blue : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            if (showSettleButton && transaction.status == TransactionStatus.pending && onSettle != null)
              IconButton(
                icon: Icon(Icons.check_circle_outline_rounded, color: theme.colorScheme.primary, size: 22),
                onPressed: onSettle,
                tooltip: 'Settle',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}
