import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/expenses/presentation/controllers/expense_controller.dart';


import 'package:chronicle/core/widgets/chronicle_button.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final Future<bool> Function({
    required double amount,
    String? description,
    String? categoryId,
    required bool isNecessary,
    required DateTime date,
  }) onSubmit;

  const AddExpenseSheet({super.key, required this.onSubmit});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isNecessary = true;
  final DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  bool _isLoading = false;

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
            'New Expense', 
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapLg,

          // Amount Input
          TextFormField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              hintText: '0.00',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapMd,

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'What did you buy?',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            textInputAction: TextInputAction.next,
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
                      initialValue: _selectedCategoryId,
                      hint: const Text('Category'),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                tooltip: 'New Category',
              ),
            ],
          ),
          AppSpacing.gapMd,

          // Necessity Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Essential Expense',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Uncheck if this was a splurge',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isNecessary,
                  onChanged: (val) => setState(() => _isNecessary = val),
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,

          // Submit Button
          ChronicleButton(
            label: 'Log Expense',
            onPressed: _submit,
            isLoading: _isLoading,
            isFullWidth: true,
          ),
          AppSpacing.gapMd,
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
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
