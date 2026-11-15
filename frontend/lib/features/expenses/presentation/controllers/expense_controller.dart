import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronicle/core/errors/app_exception.dart';
import 'package:chronicle/core/services/logger_service.dart';
import 'package:chronicle/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:chronicle/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/domain/models/budget.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/features/expenses/domain/models/category.dart';
import 'package:chronicle/features/expenses/domain/models/category_spend.dart';
import 'package:chronicle/features/expenses/domain/repositories/expense_repository.dart';
import 'package:chronicle/core/providers/supabase_provider.dart';

// ── Providers ──

final expenseDatasourceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ExpenseRemoteDatasource(supabase);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final datasource = ref.watch(expenseDatasourceProvider);
  return ExpenseRepositoryImpl(datasource);
});

// ── State ──

class ExpenseState {
  final bool isLoading;
  final String? errorMessage;
  final List<Expense> expenses;
  final List<Budget> budgets;
  final List<Transaction> transactions;
  final List<Category> categories;
  final String transactionSearchQuery;
  final TransactionFilters transactionFilters;
  final String expenseSearchQuery;
  final ExpenseFilters expenseFilters;
  final ExpenseSorting expenseSorting;

  /// Month shown on the Expenses home screen (first day of month);
  /// null = the current month.
  final DateTime? selectedMonth;

  const ExpenseState({
    this.isLoading = false,
    this.errorMessage,
    this.expenses = const [],
    this.budgets = const [],
    this.transactions = const [],
    this.categories = const [],
    this.transactionSearchQuery = '',
    this.transactionFilters = const TransactionFilters(),
    this.expenseSearchQuery = '',
    this.expenseFilters = const ExpenseFilters(),
    this.expenseSorting = ExpenseSorting.latest,
    this.selectedMonth,
  });

  ExpenseState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Expense>? expenses,
    List<Budget>? budgets,
    List<Transaction>? transactions,
    List<Category>? categories,
    String? transactionSearchQuery,
    TransactionFilters? transactionFilters,
    String? expenseSearchQuery,
    ExpenseFilters? expenseFilters,
    ExpenseSorting? expenseSorting,
    DateTime? selectedMonth,
  }) =>
      ExpenseState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        expenses: expenses ?? this.expenses,
        budgets: budgets ?? this.budgets,
        transactions: transactions ?? this.transactions,
        categories: categories ?? this.categories,
        transactionSearchQuery: transactionSearchQuery ?? this.transactionSearchQuery,
        transactionFilters: transactionFilters ?? this.transactionFilters,
        expenseSearchQuery: expenseSearchQuery ?? this.expenseSearchQuery,
        expenseFilters: expenseFilters ?? this.expenseFilters,
        expenseSorting: expenseSorting ?? this.expenseSorting,
        selectedMonth: selectedMonth ?? this.selectedMonth,
      );

  List<Transaction> get filteredTransactions {
    return transactions.where((t) {
      // Search
      if (transactionSearchQuery.isNotEmpty) {
        final query = transactionSearchQuery.toLowerCase();
        final matchesName = t.personName.toLowerCase().contains(query);
        final matchesReason = t.reason?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesReason) return false;
      }

      // Filters
      if (transactionFilters.type != null && t.type != transactionFilters.type) return false;
      if (transactionFilters.status != null && t.status != transactionFilters.status) return false;
      
      if (transactionFilters.minAmount != null && t.amount < transactionFilters.minAmount!) return false;
      if (transactionFilters.maxAmount != null && t.amount > transactionFilters.maxAmount!) return false;

      if (transactionFilters.startDate != null) {
        if (t.date.isBefore(transactionFilters.startDate!)) return false;
      }
      if (transactionFilters.endDate != null) {
        if (t.date.isAfter(transactionFilters.endDate!.add(const Duration(days: 1)))) return false;
      }

      return true;
    }).toList();
  }

  List<Expense> get filteredExpenses {
    final list = expenses.where((e) {
      // Search
      if (expenseSearchQuery.isNotEmpty) {
        final query = expenseSearchQuery.toLowerCase();
        final matchesCategory = e.category?.name.toLowerCase().contains(query) ?? false;
        final matchesDescription = e.description?.toLowerCase().contains(query) ?? false;
        if (!matchesCategory && !matchesDescription) return false;
      }

      // Filters
      if (expenseFilters.categoryId != null && e.categoryId != expenseFilters.categoryId) return false;
      if (expenseFilters.isNecessary != null && e.isNecessary != expenseFilters.isNecessary) return false;

      if (expenseFilters.minAmount != null && e.amount < expenseFilters.minAmount!) return false;
      if (expenseFilters.maxAmount != null && e.amount > expenseFilters.maxAmount!) return false;

      if (expenseFilters.startDate != null) {
        if (e.expenseDate.isBefore(expenseFilters.startDate!)) return false;
      }
      if (expenseFilters.endDate != null) {
        if (e.expenseDate.isAfter(expenseFilters.endDate!.add(const Duration(days: 1)))) return false;
      }

      return true;
    }).toList();

    // Sorting
    switch (expenseSorting) {
      case ExpenseSorting.latest:
        list.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
        break;
      case ExpenseSorting.oldest:
        list.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
        break;
      case ExpenseSorting.amountHigh:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case ExpenseSorting.amountLow:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return list;
  }

  // Helper getters
  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.amount);
  double get unnecessarySpent => expenses.where((e) => !e.isNecessary).fold(0, (sum, e) => sum + e.amount);
  
  double get currentMonthlyBudget => budgets
      .where((b) => b.type == BudgetType.monthly)
      .fold(0.0, (sum, b) => b.amount); // Simplification: taking latest or first

  double get currentWeeklyBudget => budgets
      .where((b) => b.type == BudgetType.weekly)
      .fold(0.0, (sum, b) => b.amount);

  double get youOwe => transactions
      .where((t) => t.type == TransactionType.BORROW && t.status == TransactionStatus.pending)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get othersOweYou => transactions
      .where((t) => t.type == TransactionType.LEND && t.status == TransactionStatus.pending)
      .fold(0.0, (sum, t) => sum + t.amount);

  List<Transaction> get pendingTransactions =>
      transactions.where((t) => t.status == TransactionStatus.pending).toList();

  static DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  static DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  List<Expense> _expensesSince(DateTime start) =>
      expenses.where((e) => !e.expenseDate.isBefore(start)).toList();

  double get spentThisMonth => _sum(expensesInMonth(_monthStart));
  double get spentThisWeek => _sum(_expensesSince(_weekStart));

  static double _sum(Iterable<Expense> list) => list.fold(0.0, (sum, e) => sum + e.amount);

  // ── Month view (Expenses home screen) ──

  /// First day of the month being viewed.
  DateTime get viewMonth => selectedMonth ?? _monthStart;
  bool get isViewingCurrentMonth => viewMonth == _monthStart;

  /// Earliest month with any expense — the month switcher's lower bound.
  DateTime get earliestMonth {
    if (expenses.isEmpty) return _monthStart;
    final first = expenses.map((e) => e.expenseDate).reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(first.year, first.month);
  }

  bool get canGoToPreviousMonth => viewMonth.isAfter(earliestMonth);
  bool get canGoToNextMonth => viewMonth.isBefore(_monthStart);

  /// Expenses dated within [month] (first day of month), newest first.
  List<Expense> expensesInMonth(DateTime month) {
    final next = DateTime(month.year, month.month + 1);
    return expenses
        .where((e) => !e.expenseDate.isBefore(month) && e.expenseDate.isBefore(next))
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  List<Expense> get viewMonthExpenses => expensesInMonth(viewMonth);
  double get viewMonthSpent => _sum(viewMonthExpenses);
  double get previousMonthSpent => _sum(expensesInMonth(DateTime(viewMonth.year, viewMonth.month - 1)));
  double get viewMonthNonEssential => _sum(viewMonthExpenses.where((e) => !e.isNecessary));

  /// Average per day: over days elapsed for the current month, else the
  /// whole month.
  double get viewMonthDailyAverage {
    final days = isViewingCurrentMonth
        ? DateTime.now().day
        : DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    return viewMonthSpent / days;
  }

  /// The viewed month's spending grouped by category, largest first.
  List<CategorySpend> get viewMonthBreakdown {
    final byCategory = <String?, List<Expense>>{};
    for (final e in viewMonthExpenses) {
      byCategory.putIfAbsent(e.categoryId, () => []).add(e);
    }
    final total = viewMonthSpent;
    return byCategory.entries.map((entry) {
      final amount = _sum(entry.value);
      return CategorySpend(
        categoryId: entry.key,
        name: entry.value.first.category?.name,
        amount: amount,
        count: entry.value.length,
        share: total > 0 ? amount / total : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }
}

// ── Controller (Riverpod v3 Notifier) ──

class ExpenseController extends Notifier<ExpenseState> {
  late final ExpenseRepository _repository;

  @override
  ExpenseState build() {
    _repository = ref.watch(expenseRepositoryProvider);
    return const ExpenseState();
  }

  Future<void> loadAllData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repository.getExpenses(),
        _repository.getBudgets(),
        _repository.getTransactions(),
        _repository.getCategories('expense'),
      ]);

      state = state.copyWith(
        isLoading: false,
        expenses: results[0] as List<Expense>,
        budgets: results[1] as List<Budget>,
        transactions: results[2] as List<Transaction>,
        categories: results[3] as List<Category>,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e, st) {
      LoggerService.error('Unexpected error loading expenses', error: e, stackTrace: st, tag: 'Expense');
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred');
    }
  }

  Future<bool> addExpense({
    required double amount,
    String? description,
    String? categoryId,
    required bool isNecessary,
    required DateTime date,
  }) async {
    try {
      await _repository.addExpense(
        amount: amount,
        description: description,
        categoryId: categoryId,
        isNecessary: isNecessary,
        date: date,
      );
      await loadAllData();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> updateExpense({
    required String id,
    required double amount,
    String? description,
    String? categoryId,
    required bool isNecessary,
    required DateTime date,
  }) async {
    try {
      await _repository.updateExpense(
        id: id,
        amount: amount,
        description: description,
        categoryId: categoryId,
        isNecessary: isNecessary,
        date: date,
      );
      await loadAllData();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  /// Removes the expense immediately (so a swiped row can leave the tree),
  /// then deletes it; restores it if the delete fails.
  Future<bool> deleteExpense(String id) async {
    final previous = state.expenses;
    state = state.copyWith(expenses: previous.where((e) => e.id != id).toList());
    try {
      await _repository.deleteExpense(id);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(expenses: previous, errorMessage: e.message);
      return false;
    }
  }

  // ── Month navigation ──

  void showPreviousMonth() {
    if (!state.canGoToPreviousMonth) return;
    final m = state.viewMonth;
    state = state.copyWith(selectedMonth: DateTime(m.year, m.month - 1));
  }

  void showNextMonth() {
    if (!state.canGoToNextMonth) return;
    final m = state.viewMonth;
    state = state.copyWith(selectedMonth: DateTime(m.year, m.month + 1));
  }

  Future<bool> setBudget({
    required double amount,
    required BudgetType type,
    required DateTime startDate,
  }) async {
    try {
      await _repository.setBudget(amount: amount, type: type, startDate: startDate);
      await loadAllData();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> addCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      await _repository.addCategory(name, type, icon: icon, color: color);
      await loadAllData();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> addTransaction({
    required String personName,
    required double amount,
    required TransactionType type,
    String? reason,
    required DateTime date,
  }) async {
    try {
      await _repository.addTransaction(
        personName: personName,
        amount: amount,
        type: type,
        reason: reason,
        date: date,
      );
      await loadAllData();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(transactionSearchQuery: query);
  }

  void setFilters(TransactionFilters filters) {
    state = state.copyWith(transactionFilters: filters);
  }

  void clearFilters() {
    state = state.copyWith(transactionFilters: const TransactionFilters());
  }

  void setExpenseSearchQuery(String query) {
    state = state.copyWith(expenseSearchQuery: query);
  }

  void setExpenseFilters(ExpenseFilters filters) {
    state = state.copyWith(expenseFilters: filters);
  }

  void setExpenseSorting(ExpenseSorting sorting) {
    state = state.copyWith(expenseSorting: sorting);
  }

  void clearExpenseFilters() {
    state = state.copyWith(expenseFilters: const ExpenseFilters());
  }

  Future<void> settleTransaction(String id) async {
    try {
      await _repository.updateTransactionStatus(
        id,
        TransactionStatus.settled,
        settledDate: DateTime.now(),
      );
      await loadAllData();
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadAllData();
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}

class TransactionFilters extends Equatable {
  final TransactionType? type;
  final TransactionStatus? status;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilters({
    this.type,
    this.status,
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
  });

  TransactionFilters copyWith({
    TransactionType? type,
    TransactionStatus? status,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearStatus = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TransactionFilters(
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  @override
  List<Object?> get props => [type, status, minAmount, maxAmount, startDate, endDate];
}

enum ExpenseSorting { latest, oldest, amountHigh, amountLow }

class ExpenseFilters extends Equatable {
  final String? categoryId;
  final bool? isNecessary;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExpenseFilters({
    this.categoryId,
    this.isNecessary,
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
  });

  ExpenseFilters copyWith({
    String? categoryId,
    bool? isNecessary,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    bool clearCategory = false,
    bool clearNecessity = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return ExpenseFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      isNecessary: clearNecessity ? null : (isNecessary ?? this.isNecessary),
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  @override
  List<Object?> get props => [categoryId, isNecessary, minAmount, maxAmount, startDate, endDate];
}

final expenseControllerProvider = NotifierProvider<ExpenseController, ExpenseState>(ExpenseController.new);
