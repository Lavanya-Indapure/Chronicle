import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
