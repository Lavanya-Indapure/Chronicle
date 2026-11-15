import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/presentation/widgets/category_visuals.dart';
import 'package:chronicle/features/expenses/presentation/widgets/expense_sheets.dart';

/// Read-only summary of one expense with Edit and Delete actions.
/// [onChanged] runs after a successful edit or delete (e.g. refresh dashboard).
Future<void> showExpenseDetails(
  BuildContext context,
  WidgetRef ref,
  Expense expense, {
  required Color color,
  VoidCallback? onChanged,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (sheetContext) => _ExpenseDetailSheet(
      expense: expense,
      color: color,
      onEdit: () {
        Navigator.pop(sheetContext);
        showEditExpenseSheet(context, ref, expense, onSaved: onChanged);
      },
      onDelete: () async {
        final deleted = await confirmAndDeleteExpense(sheetContext, ref, expense, onDeleted: onChanged);
        if (deleted && sheetContext.mounted) Navigator.pop(sheetContext);
      },
    ),
  );
}

class _ExpenseDetailSheet extends StatelessWidget {
  final Expense expense;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseDetailSheet({
    required this.expense,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = expense.category?.name ?? AppStrings.uncategorized;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconBadge(icon: CategoryVisuals.iconFor(expense.category?.name), color: color),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    expense.description ?? categoryName,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            AppSpacing.gapLg,
            Text('-${AppFormatters.currency(expense.amount)}', style: theme.textTheme.displayMedium),
            AppSpacing.gapLg,
            _DetailRow(icon: Icons.category_outlined, label: AppStrings.category, value: categoryName),
            _DetailRow(icon: Icons.calendar_today_outlined, label: AppStrings.date, value: AppFormatters.dayMonthYear(expense.expenseDate)),
            _DetailRow(
              icon: expense.isNecessary ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
              label: AppStrings.essential,
              value: expense.isNecessary ? AppStrings.yes : AppStrings.no,
              valueColor: expense.isNecessary ? null : AppColors.warning,
            ),
            AppSpacing.gapLg,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text(AppStrings.delete),
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text(AppStrings.edit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.md + 2, color: theme.colorScheme.onSurfaceVariant),
          AppSpacing.hGapMd,
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
