import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';

/// Pending lend/borrow row with a settle action.
class DebtListTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onSettle;

  const DebtListTile({super.key, required this.transaction, required this.onSettle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLend = transaction.type == TransactionType.LEND;
    final color = isLend ? AppColors.success : AppColors.error;
    final subtitle = [
      isLend ? AppStrings.lent : AppStrings.borrowed,
      transaction.reason,
      AppFormatters.shortDate(transaction.date),
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md - 4, AppSpacing.xs, AppSpacing.md - 4),
      child: Row(
        children: [
          IconBadge(icon: isLend ? Icons.north_east_rounded : Icons.south_west_rounded, color: color),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.personName, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(
            AppFormatters.currency(transaction.amount),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded),
            color: theme.colorScheme.onSurfaceVariant,
            tooltip: AppStrings.settle,
            onPressed: onSettle,
          ),
        ],
      ),
    );
  }
}
