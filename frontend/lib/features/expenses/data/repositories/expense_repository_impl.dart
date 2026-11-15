import 'package:chronicle/core/errors/error_handler.dart';
import 'package:chronicle/core/services/logger_service.dart';
import 'package:chronicle/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/domain/models/category.dart';
import 'package:chronicle/features/expenses/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDatasource _datasource;

  ExpenseRepositoryImpl(this._datasource);

  @override
  Future<List<Expense>> getExpenses({DateTime? start, DateTime? end}) async {
    try {
      final data = await _datasource.getExpenses(start: start, end: end);
      return data.map((e) => Expense.fromJson(e)).toList();
    } catch (e, st) {
      LoggerService.error('Failed to get expenses', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Expense> addExpense({
    required double amount,
    String? description,
    String? categoryId,
    required bool isNecessary,
    required DateTime date,
  }) async {
    try {
      final data = {
        'user_id': _datasource.userId,
        'amount': amount,
        'description': description,
        'category_id': categoryId,
        'is_necessary': isNecessary,
        'expense_date': date.toIso8601String().split('T').first,
      };
      final result = await _datasource.insertExpense(data);
      return Expense.fromJson(result);
    } catch (e, st) {
      LoggerService.error('Failed to add expense', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> updateExpense({
    required String id,
    required double amount,
    String? description,
    String? categoryId,
    required bool isNecessary,
    required DateTime date,
  }) async {
    try {
      await _datasource.updateExpense(id, {
        'amount': amount,
        'description': description,
        'category_id': categoryId,
        'is_necessary': isNecessary,
        'expense_date': date.toIso8601String().split('T').first,
      });
    } catch (e, st) {
      LoggerService.error('Failed to update expense', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await _datasource.deleteExpense(id);
    } catch (e, st) {
      LoggerService.error('Failed to delete expense', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<Budget>> getBudgets() async {
    try {
      final data = await _datasource.getBudgets();
      return data.map((e) => Budget.fromJson(e)).toList();
    } catch (e, st) {
      LoggerService.error('Failed to get budgets', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> setBudget({
    required double amount,
    required BudgetType type,
    required DateTime startDate,
  }) async {
    try {
      final data = {
        'user_id': _datasource.userId,
        'amount': amount,
        'budget_type': type.name,
        'start_date': startDate.toIso8601String().split('T').first,
      };
      await _datasource.upsertBudget(data);
    } catch (e, st) {
      LoggerService.error('Failed to set budget', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    try {
      final data = await _datasource.getTransactions();
      return data.map((e) => Transaction.fromJson(e)).toList();
    } catch (e, st) {
      LoggerService.error('Failed to get transactions', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Transaction> addTransaction({
    required String personName,
    required double amount,
    required TransactionType type,
    String? reason,
    required DateTime date,
  }) async {
    try {
      final data = {
        'user_id': _datasource.userId,
        'person_name': personName,
        'amount': amount,
        'type': type.name,
        'status': TransactionStatus.pending.name,
        'reason': reason,
        'lending_date': date.toIso8601String().split('T').first,
      };
      final result = await _datasource.insertTransaction(data);
      return Transaction.fromJson(result);
    } catch (e, st) {
      LoggerService.error('Failed to add transaction', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> updateTransactionStatus(String id, TransactionStatus status, {DateTime? settledDate}) async {
    try {
      await _datasource.updateTransactionStatus(id, status.name, settledDate: settledDate);
    } catch (e, st) {
      LoggerService.error('Failed to update transaction status', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _datasource.deleteTransaction(id);
    } catch (e, st) {
      LoggerService.error('Failed to delete transaction', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<Category>> getCategories(String type) async {
    try {
      final data = await _datasource.getCategories(type);
      return data.map((e) => Category.fromJson(e)).toList();
    } catch (e, st) {
      LoggerService.error('Failed to get categories', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Category> addCategory(String name, String type, {String? icon, String? color}) async {
    try {
      final data = {
        'user_id': _datasource.userId,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
      };
      final result = await _datasource.insertCategory(data);
      return Category.fromJson(result);
    } catch (e, st) {
      LoggerService.error('Failed to add category', error: e, stackTrace: st, tag: 'Expense');
      throw ErrorHandler.handle(e);
    }
  }
}
