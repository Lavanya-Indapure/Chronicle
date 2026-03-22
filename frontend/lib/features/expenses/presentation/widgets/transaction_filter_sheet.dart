import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';

import 'package:chronicle/core/widgets/chronicle_button.dart';

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
                'Filter Debts', 
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(expenseControllerProvider.notifier).clearFilters();
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
                  // Type Filter
                  _buildSectionHeader(theme, 'Type'),
                  AppSpacing.gapSm,
                  SegmentedButton<TransactionType?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('Both')),
                      ButtonSegment(value: TransactionType.lend, label: Text('Lent'), icon: Icon(Icons.arrow_upward_rounded, size: 18)),
                      ButtonSegment(value: TransactionType.borrow, label: Text('Borrowed'), icon: Icon(Icons.arrow_downward_rounded, size: 18)),
                    ],
                    selected: {_filters.type},
                    onSelectionChanged: (val) => setState(() => _filters = _filters.copyWith(type: val.first, clearType: val.first == null)),
                    showSelectedIcon: false,
                  ),
                  AppSpacing.gapLg,

                  // Status Filter
                  _buildSectionHeader(theme, 'Status'),
                  AppSpacing.gapSm,
                  SegmentedButton<TransactionStatus?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(value: TransactionStatus.pending, label: Text('Pending'), icon: Icon(Icons.pending_actions_rounded, size: 18)),
                      ButtonSegment(value: TransactionStatus.settled, label: Text('Settled'), icon: Icon(Icons.check_circle_outline_rounded, size: 18)),
                    ],
                    selected: {_filters.status},
                    onSelectionChanged: (val) => setState(() => _filters = _filters.copyWith(status: val.first, clearStatus: val.first == null)),
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
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
