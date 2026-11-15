import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/draft_form_mixin.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/features/expenses/domain/models/expense.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final Future<bool> Function({
    required double amount,
    String? description,
    String? categoryId,
    required bool isNecessary,
    required DateTime date,
  }) onSubmit;

  /// When set, the sheet edits this expense instead of creating a new one.
  final Expense? initial;

  const AddExpenseSheet({super.key, required this.onSubmit, this.initial});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> with DraftFormMixin<AddExpenseSheet> {
  /// Starting date (the expense's date when editing, else today).
  late final DateTime _startDate = widget.initial?.expenseDate ?? DateTime.now();
  late final _amountController = TextEditingController(
    text: widget.initial == null ? null : _formatAmount(widget.initial!.amount),
  );
  late final _descriptionController = TextEditingController(text: widget.initial?.description);
  late bool _isNecessary = widget.initial?.isNecessary ?? true;
  late DateTime _selectedDate = _startDate;
  late String? _selectedCategoryId = widget.initial?.categoryId;
  bool _isLoading = false;

  bool get _isEditing => widget.initial != null;

  // ── Draft ──
  @override
  String get draftKey => _isEditing ? 'expense:edit:${widget.initial!.id}' : 'expense:new';

  @override
  Map<String, Object?> captureDraft() => {
        'amount': _amountController.text,
        'description': _descriptionController.text,
        'categoryId': _selectedCategoryId,
        'isNecessary': _isNecessary,
        'date': _selectedDate,
      };

  @override
  void restoreDraft(Map<String, Object?> draft) {
    final initial = widget.initial;
    _amountController.text =
        draft['amount'] as String? ?? (initial == null ? '' : _formatAmount(initial.amount));
    _descriptionController.text = draft['description'] as String? ?? initial?.description ?? '';
    _selectedCategoryId = draft.containsKey('categoryId') ? draft['categoryId'] as String? : initial?.categoryId;
    _isNecessary = draft['isNecessary'] as bool? ?? initial?.isNecessary ?? true;
    _selectedDate = draft['date'] as DateTime? ?? _startDate;
  }

  @override
  void initState() {
    super.initState();
    initDraft();
  }

  /// 120.0 → "120", 99.5 → "99.5"
  static String _formatAmount(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    setState(() => _isLoading = true);
    final success = await widget.onSubmit(
      amount: amount,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      categoryId: _selectedCategoryId,
      isNecessary: _isNecessary,
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
          Text(_isEditing ? AppStrings.editExpense : AppStrings.addExpense, style: theme.textTheme.titleLarge),
          AppSpacing.gapMd,
          if (draftRestored) ...[
            DraftRestoredBanner(onDiscard: discardDraft),
            AppSpacing.gapMd,
          ],

          // Amount
          TextFormField(
            controller: _amountController,
            autofocus: !_isEditing && !draftRestored,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: AppStrings.amount,
              prefixIcon: Icon(Icons.currency_rupee_rounded),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapMd,

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.description_outlined),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          AppSpacing.gapMd,

          // Category Selection
          Row(
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final categories = ref.watch(expenseControllerProvider).categories;
                    return DropdownButtonFormField<String>(
                        isExpanded: true, // ellipsize long labels instead of overflowing
                      value: _selectedCategoryId,
                      hint: const Text('Select Category'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    );
                  },
                ),
              ),
              AppSpacing.hGapSm,
              IconButton.filledTonal(
                onPressed: _showAddCategoryDialog,
                icon: const Icon(Icons.add),
                tooltip: 'Add New Category',
              ),
            ],
          ),
          AppSpacing.gapMd,

          // Date
          Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: AppSpacing.borderRadiusLg,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: _pickDate,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text(AppStrings.date),
              trailing: Text(AppFormatters.dayMonthYear(_selectedDate), style: theme.textTheme.titleSmall),
            ),
          ),
          AppSpacing.gapSm,

          // Necessity Toggle
          SwitchListTile(
            title: const Text('Was this necessary?'),
            subtitle: const Text('Used for savings insights'),
            value: _isNecessary,
            onChanged: (val) => setState(() => _isNecessary = val),
            secondary: const Icon(Icons.info_outline),
            contentPadding: EdgeInsets.zero,
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
                : Text(_isEditing ? AppStrings.saveChanges : AppStrings.saveExpense),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Groceries, Gym',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref.read(expenseControllerProvider.notifier).addCategory(
                  name: name,
                  type: 'expense',
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
