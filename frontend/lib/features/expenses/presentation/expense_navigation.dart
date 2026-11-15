import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/screens/expense_categories_screen.dart';
import 'package:chronicle/features/expenses/presentation/screens/expense_history_screen.dart';

/// Opens Expense History filtered to the viewed month (and optionally one
/// category), clearing the filter again on return.
Future<void> openMonthHistory(BuildContext context, WidgetRef ref, {String? categoryId}) async {
  final controller = ref.read(expenseControllerProvider.notifier);
  final month = ref.read(expenseControllerProvider).viewMonth;
  controller
    ..setExpenseSearchQuery('')
    ..setExpenseFilters(ExpenseFilters(
      categoryId: categoryId,
      startDate: month,
      endDate: DateTime(month.year, month.month + 1, 0),
    ));
  await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen()));
  controller.clearExpenseFilters();
}

/// Opens the full per-category breakdown for the viewed month.
Future<void> openAllCategories(BuildContext context) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseCategoriesScreen()));
