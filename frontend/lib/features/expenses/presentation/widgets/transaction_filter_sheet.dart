import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';

class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key});

  @override
  ConsumerState<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends ConsumerState<TransactionFilterSheet> {
  late TransactionFilters _filters;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = ref.read(expenseControllerProvider).transactionFilters;
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

    ref.read(expenseControllerProvider.notifier).setFilters(finalFilters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardAwareSheet(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Transactions', style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  ref.read(expenseControllerProvider.notifier).clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          AppSpacing.gapMd,

          // Type Filter
          Text('Type', style: theme.textTheme.titleSmall),
          AppSpacing.gapSm,
          SegmentedButton<TransactionType?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All')),
              ButtonSegment(value: TransactionType.LEND, label: Text('Lend')),
              ButtonSegment(value: TransactionType.BORROW, label: Text('Borrow')),
            ],
            selected: {_filters.type},
            onSelectionChanged: (val) => setState(() => _filters = _filters.copyWith(type: val.first, clearType: val.first == null)),
          ),
          AppSpacing.gapMd,

          // Status Filter
          Text('Status', style: theme.textTheme.titleSmall),
          AppSpacing.gapSm,
          SegmentedButton<TransactionStatus?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Both')),
              ButtonSegment(value: TransactionStatus.pending, label: Text('Pending')),
              ButtonSegment(value: TransactionStatus.settled, label: Text('Settled')),
            ],
            selected: {_filters.status},
            onSelectionChanged: (val) => setState(() => _filters = _filters.copyWith(status: val.first, clearStatus: val.first == null)),
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
                lastDate: DateTime.now().add(const Duration(days: 365)),
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
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
