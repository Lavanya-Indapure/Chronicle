import 'package:equatable/equatable.dart';

/// One category's slice of a period's spending. [name] is null for
/// uncategorised expenses.
class CategorySpend extends Equatable {
  final String? name;
  final double amount;
  final int count;
  final double share; // 0.0 – 1.0 of the period total

  const CategorySpend({
    required this.name,
    required this.amount,
    required this.count,
    required this.share,
  });

  @override
  List<Object?> get props => [name, amount, count, share];
}
