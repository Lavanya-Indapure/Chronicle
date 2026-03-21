import 'package:equatable/equatable.dart';

enum BudgetType {
  weekly,
  monthly;

  String get label => name[0].toUpperCase() + name.substring(1);
}

class Budget extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final BudgetType type;
  final DateTime startDate;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.startDate,
    required this.createdAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      type: BudgetType.values.firstWhere(
        (e) => e.name == json['budget_type'],
        orElse: () => BudgetType.monthly,
      ),
      startDate: DateTime.parse(json['start_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'budget_type': type.name,
      'start_date': startDate.toIso8601String().split('T').first,
    };
  }

  @override
  List<Object?> get props => [id, userId, amount, type, startDate, createdAt];
}
