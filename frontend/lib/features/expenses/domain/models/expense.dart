import 'package:equatable/equatable.dart';
import 'package:chronicle/features/expenses/domain/models/category.dart';

class Expense extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String? description;
  final String? categoryId;
  final bool isNecessary;
  final DateTime expenseDate;
  final DateTime createdAt;
  final Category? category;

  const Expense({
    required this.id,
    required this.userId,
    required this.amount,
    this.description,
    this.categoryId,
    this.isNecessary = true,
    required this.expenseDate,
    required this.createdAt,
    this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      categoryId: json['category_id'],
      isNecessary: json['is_necessary'] ?? true,
      expenseDate: DateTime.parse(json['expense_date']),
      createdAt: DateTime.parse(json['created_at']),
      category: json['categories'] != null ? Category.fromJson(json['categories']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'description': description,
      'category_id': categoryId,
      'is_necessary': isNecessary,
      'expense_date': expenseDate.toIso8601String().split('T').first,
    };
  }

  @override
  List<Object?> get props => [id, userId, amount, description, categoryId, isNecessary, expenseDate, createdAt];
}
