import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/core/widgets/chronicle_button.dart';

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

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Expenses', 
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(expenseControllerProvider.notifier).clearExpenseFilters();
                  ref.read(expenseControllerProvider.notifier).setExpenseSorting(ExpenseSorting.latest);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset'),
              ),
            ],
          ),
          AppSpacing.gapLg,

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sorting
                  _buildSectionHeader(theme, 'Sort By'),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: ExpenseSorting.values.map((s) {
                      final label = s == ExpenseSorting.latest ? 'Latest' : 
                                    s == ExpenseSorting.oldest ? 'Oldest' :
                                    s == ExpenseSorting.amountHigh ? 'Highest Amount' : 'Lowest Amount';
                      final isSelected = _sorting == s;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _sorting = s),
                      );
                    }).toList(),
                  ),
                  AppSpacing.gapLg,

                  // Category Filter
                  _buildSectionHeader(theme, 'Category'),
                  AppSpacing.gapSm,
                  DropdownButtonFormField<String?>(
                    initialValue: _filters.categoryId,
                    hint: const Text('All Categories'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (val) => setState(() => _filters = _filters.copyWith(categoryId: val, clearCategory: val == null)),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                  ),
                  AppSpacing.gapLg,

                  // Necessity Filter
                  _buildSectionHeader(theme, 'Type'),
                  AppSpacing.gapSm,
                  SegmentedButton<bool?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(value: true, label: Text('Essential'), icon: Icon(Icons.check_circle_outline, size: 18)),
                      ButtonSegment(value: false, label: Text('Splurge'), icon: Icon(Icons.star_outline, size: 18)),
                    ],
                    selected: {_filters.isNecessary},
                    onSelectionChanged: (val) => setState(() => _filters = _filters.copyWith(isNecessary: val.first, clearNecessity: val.first == null)),
                    showSelectedIcon: false,
                  ),
                  AppSpacing.gapLg,

                  // Amount Range
                  _buildSectionHeader(theme, 'Amount Range'),
                  AppSpacing.gapSm,
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Min', 
                            prefixText: '₹',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: TextField(
                          controller: _maxAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Max', 
                            prefixText: '₹',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapLg,

                  // Date Range
                  _buildSectionHeader(theme, 'Date Range'),
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
                    icon: const Icon(Icons.date_range_rounded),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    label: Text(_filters.startDate != null
                        ? '${_filters.startDate!.toString().split(' ').first} - ${_filters.endDate!.toString().split(' ').first}'
                        : 'Select Date Range'),
                  ),
                  AppSpacing.gapLg,
                ],
              ),
            ),
          ),

          // Apply Button
          ChronicleButton(
            label: 'Show Results',
            onPressed: _apply,
            isFullWidth: true,
          ),
          AppSpacing.gapMd,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}
