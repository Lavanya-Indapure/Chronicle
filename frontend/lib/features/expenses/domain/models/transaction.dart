import 'package:equatable/equatable.dart';

enum TransactionType {
  LEND,
  BORROW;

  String get label => name[0].toUpperCase() + name.substring(1);
}

enum TransactionStatus {
  pending,
  settled;

  String get label => name[0].toUpperCase() + name.substring(1);
}

class Transaction extends Equatable {
  final String id;
  final String userId;
  final String personName;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String? reason;
  final DateTime date;
  final DateTime? settledDate;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required this.type,
    required this.status,
    this.reason,
    required this.date,
    this.settledDate,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      personName: json['person_name'],
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.LEND,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      reason: json['reason'], // Renamed from 'note' in the prompt/migration
      date: DateTime.parse(json['lending_date']),
      settledDate: json['settled_date'] != null ? DateTime.parse(json['settled_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'person_name': personName,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'reason': reason,
      'lending_date': date.toIso8601String().split('T').first,
      'settled_date': settledDate?.toIso8601String().split('T').first,
    };
  }

  @override
  List<Object?> get props => [id, userId, personName, amount, type, status, reason, date, settledDate, createdAt];
}
