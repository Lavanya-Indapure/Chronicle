import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';

/// Sheet letting the user pick which budget (weekly/monthly) to set.
Future<void> showBudgetOptionsSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_view_week_rounded),
              title: const Text(AppStrings.setWeeklyBudget),
              onTap: () {
                Navigator.pop(sheetContext);
                showSetBudgetDialog(context, ref, BudgetType.weekly);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text(AppStrings.setMonthlyBudget),
              onTap: () {
                Navigator.pop(sheetContext);
                showSetBudgetDialog(context, ref, BudgetType.monthly);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Asks for an amount, confirms, then saves the budget.
Future<void> showSetBudgetDialog(BuildContext context, WidgetRef ref, BudgetType type) {
  return showDialog(
    context: context,
    builder: (dialogContext) => _SetBudgetDialog(type: type, ref: ref),
  );
}

class _SetBudgetDialog extends StatefulWidget {
  final BudgetType type;
  final WidgetRef ref;

  const _SetBudgetDialog({required this.type, required this.ref});

  @override
  State<_SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<_SetBudgetDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_controller.text.trim());
    if (amount == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text(AppStrings.confirmBudgetTitle),
        content: const Text(AppStrings.confirmBudgetMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(confirmContext, false), child: const Text(AppStrings.no)),
          TextButton(onPressed: () => Navigator.pop(confirmContext, true), child: const Text(AppStrings.yes)),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.ref.read(expenseControllerProvider.notifier).setBudget(
          amount: amount,
          type: widget.type,
          startDate: DateTime.now(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${AppStrings.set} ${widget.type.label} ${AppStrings.budget}'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: const InputDecoration(
          labelText: AppStrings.budgetAmount,
          prefixIcon: Icon(Icons.currency_rupee_rounded),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
        TextButton(onPressed: _save, child: const Text(AppStrings.set)),
      ],
    );
  }
}
