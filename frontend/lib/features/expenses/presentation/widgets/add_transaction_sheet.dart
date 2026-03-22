import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';

import 'package:chronicle/core/widgets/chronicle_button.dart';

class AddTransactionSheet extends StatefulWidget {
  final Future<bool> Function({
    required String personName,
    required double amount,
    required TransactionType type,
    String? reason,
    required DateTime date,
  }) onSubmit;

  const AddTransactionSheet({super.key, required this.onSubmit});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  TransactionType _type = TransactionType.lend;
  final DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    if (name.isEmpty || amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    setState(() => _isLoading = true);
    final success = await widget.onSubmit(
      personName: name,
      amount: amount,
      type: _type,
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      date: _selectedDate,
    );

    if (success && mounted) Navigator.pop(context);
    if (mounted) setState(() => _isLoading = false);
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
          Text(
            'New Debt',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapLg,

          // Type Toggle
          SegmentedButton<TransactionType>(
            segments: [
              ButtonSegment(
                value: TransactionType.lend,
                label: const Text('I Lent'),
                icon: Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.green.shade700)
              ),
              ButtonSegment(
                value: TransactionType.borrow,
                label: const Text('I Borrowed'),
                icon: Icon(Icons.arrow_downward_rounded, size: 18, color: theme.colorScheme.error)
              ),
            ],
            selected: {_type},
            onSelectionChanged: (val) => setState(() => _type = val.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: _type == TransactionType.lend
                ? Colors.green.withValues(alpha: 0.1)
                : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              selectedForegroundColor: _type == TransactionType.lend
                ? Colors.green.shade900
                : theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          AppSpacing.gapLg,

          // Person Name
          TextFormField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Who involved?',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapMd,

          // Amount
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'How much?',
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              hintText: '0.00',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapMd,

          // Reason
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Reason (optional)',
              prefixIcon: const Icon(Icons.notes_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          AppSpacing.gapLg,

          // Submit
          ChronicleButton(
            label: _type == TransactionType.lend ? 'Log Loan' : 'Log Borrowing',
            onPressed: _submit,
            isLoading: _isLoading,
            isFullWidth: true,
            color: _type == TransactionType.lend ? Colors.green : theme.colorScheme.primary,
          ),
          AppSpacing.gapMd,
        ],
      ),
    );
  }
}
