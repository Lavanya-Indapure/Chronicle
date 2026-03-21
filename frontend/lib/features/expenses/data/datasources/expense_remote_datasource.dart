import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseRemoteDatasource {
  final SupabaseClient client;

  ExpenseRemoteDatasource(this.client);

  String get userId => client.auth.currentUser!.id;

  // ── Expenses ──

  Future<List<Map<String, dynamic>>> getExpenses({
    DateTime? start,
    DateTime? end,
  }) async {
    var query = client.from('expenses').select('*, categories(*)').eq('user_id', userId);

    if (start != null) {
      query = query.gte('expense_date', start.toIso8601String().split('T').first);
    }
    if (end != null) {
      query = query.lte('expense_date', end.toIso8601String().split('T').first);
    }

    final response = await query.order('expense_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> insertExpense(Map<String, dynamic> data) async {
    final response = await client.from('expenses').insert(data).select().single();
    return response;
  }

  Future<void> deleteExpense(String id) async {
    await client.from('expenses').delete().eq('id', id);
  }

  // ── Budgets ──

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final response = await client
        .from('budget_history')
        .select('*')
        .eq('user_id', userId)
        .order('start_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> upsertBudget(Map<String, dynamic> data) async {
    // Unique constraint on (user_id, start_date, budget_type) handles the upsert
    await client.from('budget_history').upsert(data);
  }

  // ── Transactions (Lending/Borrowing) ──

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final response = await client
        .from('transactions')
        .select('*')
        .eq('user_id', userId)
        .order('lending_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> insertTransaction(Map<String, dynamic> data) async {
    final response = await client.from('transactions').insert(data).select().single();
    return response;
  }

  Future<void> updateTransactionStatus(String id, String status, {DateTime? settledDate}) async {
    final data = {
      'status': status,
      'settled_date': settledDate?.toIso8601String().split('T').first,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await client.from('transactions').update(data).eq('id', id);
  }

  Future<void> deleteTransaction(String id) async {
    await client.from('transactions').delete().eq('id', id);
  }

  // ── Categories ──

  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final response = await client
        .from('categories')
        .select('*')
        .eq('type', type)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> insertCategory(Map<String, dynamic> data) async {
    final response = await client.from('categories').insert(data).select().single();
    return response;
  }
}
