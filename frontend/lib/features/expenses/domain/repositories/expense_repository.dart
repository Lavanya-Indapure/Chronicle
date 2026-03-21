import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/domain/models/category.dart';

abstract class ExpenseRepository {
  // Expenses
  Future<List<Expense>> getExpenses({DateTime? start, DateTime? end});
  Future<Expense> addExpense({
    required double amount,
    String? description,
    String? categoryId,
    required bool isNecessary,
    required DateTime date,
  });
  Future<void> deleteExpense(String id);

  // Budgets
  Future<List<Budget>> getBudgets();
  Future<void> setBudget({
    required double amount,
    required BudgetType type,
    required DateTime startDate,
  });

  // Transactions
  Future<List<Transaction>> getTransactions();
  Future<Transaction> addTransaction({
    required String personName,
    required double amount,
    required TransactionType type,
    String? reason,
    required DateTime date,
  });
  Future<void> updateTransactionStatus(String id, TransactionStatus status, {DateTime? settledDate});
  Future<void> deleteTransaction(String id);

  // Categories
  Future<List<Category>> getCategories(String type);
  Future<Category> addCategory(String name, String type, {String? icon, String? color});
}
