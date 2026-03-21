import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';

class ExpenseFilterSheet extends ConsumerStatefulWidget {
  const ExpenseFilterSheet({super.key});

  @override
  ConsumerState<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends ConsumerState<ExpenseFilterSheet> {
  late ExpenseFilters _filters;
  late ExpenseSorting _sorting;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(expenseControllerProvider);
    _filters = state.expenseFilters;
    _sorting = state.expenseSorting;
    if (_filters.minAmount != null) _minAmountController.text = _filters.minAmount!.toStringAsFixed(0);
    if (_filters.maxAmount != null) _maxAmountController.text = _filters.maxAmount!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_minAmountController.text);
    final max = double.tryParse(_maxAmountController.text);
    
    final finalFilters = _filters.copyWith(
      minAmount: min,
      maxAmount: max,
    );

    ref.read(expenseControllerProvider.notifier).setExpenseFilters(finalFilters);
    ref.read(expenseControllerProvider.notifier).setExpenseSorting(_sorting);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(expenseControllerProvider).categories;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter expenses', style: theme.textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    ref.read(expenseControllerProvider.notifier).clearExpenseFilters();
                    ref.read(expenseControllerProvider.notifier).setExpenseSorting(ExpenseSorting.latest);
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            AppSpacing.gapMd,

            // Sorting
            Text('Sort By', style: theme.textTheme.titleSmall),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: ExpenseSorting.values.map((s) {
                final label = s == ExpenseSorting.latest ? 'Latest' : 
                              s == ExpenseSorting.oldest ? 'Oldest' :
                              s == ExpenseSorting.amountHigh ? 'Highest Amount' : 'Lowest Amount';
                return ChoiceChip(
                  label: Text(label),
                  selected: _sorting == s,
                  onSelected: (val) => setState(() => _sorting = s),
                );
              }).toList(),
            ),
            AppSpacing.gapMd,

            // Category Filter
            Text('Category', style: theme.textTheme.titleSmall),
            AppSpacing.gapSm,
            DropdownButtonFormField<String?>(
              value: _filters.categoryId,
              hint: const Text('All Categories'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (val) => setState(() => _filters = _filters.copyWith(categoryId: val, clearCategory: val == null)),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            ),
            AppSpacing.gapMd,

            // Necessity Filter
            Text('Necessity', style: theme.textTheme.titleSmall),
            AppSpacing.gapSm,
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(value: true, label: Text('Necessary')),
                ButtonSegment(value: false, label: Text('Unnecessary')),
              ],
              selected: {_filters.isNecessary},
              onSelectionChanged: (val) => setState(() => _filters = _filters.copyWith(isNecessary: val.first, clearNecessity: val.first == null)),
            ),
            AppSpacing.gapMd,

            // Amount Range
            Text('Amount Range', style: theme.textTheme.titleSmall),
            AppSpacing.gapSm,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min', prefixText: '₹'),
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: TextField(
                    controller: _maxAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max', prefixText: '₹'),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,

            // Date Range
            Text('Date Range', style: theme.textTheme.titleSmall),
            AppSpacing.gapSm,
            OutlinedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _filters.startDate != null && _filters.endDate != null
                      ? DateTimeRange(start: _filters.startDate!, end: _filters.endDate!)
                      : null,
                );
                if (range != null) {
                  setState(() => _filters = _filters.copyWith(startDate: range.start, endDate: range.end));
                }
              },
              icon: const Icon(Icons.date_range),
              label: Text(_filters.startDate != null
                  ? '${_filters.startDate!.toString().split(' ').first} - ${_filters.endDate!.toString().split(' ').first}'
                  : 'Select Range'),
            ),
            AppSpacing.gapLg,

            // Apply Button
            FilledButton(
              onPressed: _apply,
              child: const Text('Apply Results'),
            ),
          ],
        ),
      ),
    );
  }
}
