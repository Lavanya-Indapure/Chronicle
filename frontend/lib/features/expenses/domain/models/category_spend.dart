import 'package:equatable/equatable.dart';

/// One category's slice of a period's spending. [categoryId] and [name] are
/// null for uncategorised expenses.
class CategorySpend extends Equatable {
  final String? categoryId;
  final String? name;
  final double amount;
  final int count;
  final double share; // 0.0 – 1.0 of the period total

  const CategorySpend({
    this.categoryId,
    required this.name,
    required this.amount,
    required this.count,
    required this.share,
  });

  @override
  List<Object?> get props => [categoryId, name, amount, count, share];
}
