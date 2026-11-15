import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/presentation/expense_navigation.dart';
import 'package:chronicle/features/expenses/presentation/widgets/category_breakdown_section.dart';

/// Full category breakdown (large ring + a tile per category) for the month
/// selected on the Expenses screen. Tap a tile to list its expenses.
class ExpenseCategoriesScreen extends ConsumerWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(AppStrings.allCategories),
            Text(AppFormatters.monthYear(state.viewMonth), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
        children: [
          CategoryBreakdownSection(
            breakdown: state.viewMonthBreakdown,
            total: state.viewMonthSpent,
            month: state.viewMonth,
            onCategoryTap: (c) => openMonthHistory(context, ref, categoryId: c.categoryId),
          ),
        ],
      ),
    );
  }
}
