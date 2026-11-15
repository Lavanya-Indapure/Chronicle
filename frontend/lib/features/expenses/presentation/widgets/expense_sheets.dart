import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/widgets/add_expense_sheet.dart';
import 'package:chronicle/features/expenses/presentation/widgets/add_transaction_sheet.dart';

/// Shared entry points for the expense bottom sheets, used by the Expenses
/// screen and the global Quick Add button.
///
/// [onSaved] runs after a successful save (e.g. to refresh the dashboard).

Future<void> showAddExpenseSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => AddExpenseSheet(
      onSubmit: ({required amount, description, categoryId, required isNecessary, required date}) async {
        final ok = await ref.read(expenseControllerProvider.notifier).addExpense(
              amount: amount,
              description: description,
              categoryId: categoryId,
              isNecessary: isNecessary,
              date: date,
            );
        if (ok) onSaved?.call();
        return ok;
      },
    ),
  );
}

Future<void> showEditExpenseSheet(
  BuildContext context,
  WidgetRef ref,
  Expense expense, {
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => AddExpenseSheet(
      initial: expense,
      onSubmit: ({required amount, description, categoryId, required isNecessary, required date}) async {
        final ok = await ref.read(expenseControllerProvider.notifier).updateExpense(
              id: expense.id,
              amount: amount,
              description: description,
              categoryId: categoryId,
              isNecessary: isNecessary,
              date: date,
            );
        if (ok) onSaved?.call();
        return ok;
      },
    ),
  );
}

/// "Delete this expense?" dialog. Returns true if the user confirmed.
Future<bool> confirmDeleteExpense(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(AppStrings.deleteExpense),
      content: const Text(AppStrings.deleteExpenseConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text(AppStrings.delete),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Asks for confirmation, then deletes. Returns true if deleted.
Future<bool> confirmAndDeleteExpense(BuildContext context, WidgetRef ref, Expense expense, {VoidCallback? onDeleted}) async {
  if (!await confirmDeleteExpense(context)) return false;
  final ok = await ref.read(expenseControllerProvider.notifier).deleteExpense(expense.id);
  if (ok) onDeleted?.call();
  return ok;
}

Future<void> showAddTransactionSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => AddTransactionSheet(
      onSubmit: ({required personName, required amount, required type, reason, required date}) async {
        final ok = await ref.read(expenseControllerProvider.notifier).addTransaction(
              personName: personName,
              amount: amount,
              type: type,
              reason: reason,
              date: date,
            );
        if (ok) onSaved?.call();
        return ok;
      },
    ),
  );
}
