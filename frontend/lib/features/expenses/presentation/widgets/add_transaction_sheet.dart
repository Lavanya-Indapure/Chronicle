import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/domain/models/transaction.dart';
import 'package:chronicle/core/widgets/draft_form_mixin.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';

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

class _AddTransactionSheetState extends State<AddTransactionSheet> with DraftFormMixin<AddTransactionSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  TransactionType _type = TransactionType.LEND;
  final DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // ── Draft ──
  @override
  String get draftKey => 'debt:new';

  @override
  Map<String, Object?> captureDraft() => {
        'name': _nameController.text,
        'amount': _amountController.text,
        'reason': _reasonController.text,
        'type': _type,
      };

  @override
  void restoreDraft(Map<String, Object?> draft) {
    _nameController.text = draft['name'] as String? ?? '';
    _amountController.text = draft['amount'] as String? ?? '';
    _reasonController.text = draft['reason'] as String? ?? '';
    _type = draft['type'] as TransactionType? ?? TransactionType.LEND;
  }

  @override
  void initState() {
    super.initState();
    initDraft();
  }

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

    if (success) markSubmitted();
    if (success && mounted) Navigator.pop(context);
    if (mounted) setState(() => _isLoading = false);
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
          Text('Add Transaction', style: theme.textTheme.titleLarge),
          AppSpacing.gapMd,
          if (draftRestored) ...[
            DraftRestoredBanner(onDiscard: discardDraft),
            AppSpacing.gapMd,
          ],

          // Type Toggle
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(value: TransactionType.LEND, label: Text('Lend'), icon: Icon(Icons.archive_outlined)),
              ButtonSegment(value: TransactionType.BORROW, label: Text('Borrow'), icon: Icon(Icons.unarchive_outlined)),
            ],
            selected: {_type},
            onSelectionChanged: (val) => setState(() => _type = val.first),
          ),
          AppSpacing.gapMd,

          // Person Name
          TextFormField(
            controller: _nameController,
            autofocus: !draftRestored,
            decoration: const InputDecoration(
              labelText: 'Person Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapMd,

          // Amount
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.attach_money),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapMd,

          // Reason
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              prefixIcon: Icon(Icons.notes),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          AppSpacing.gapMd,

          // Submit
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_type == TransactionType.LEND ? 'Log Loan' : 'Log Borrowing'),
          ),
        ],
      ),
    );
  }
}
