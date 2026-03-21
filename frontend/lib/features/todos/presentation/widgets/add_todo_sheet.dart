import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';

/// Bottom sheet to add a new todo.
class AddTodoSheet extends StatefulWidget {
  final Future<bool> Function(String title, String? description, RecurrenceType type) onSubmit;

  const AddTodoSheet({super.key, required this.onSubmit});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  RecurrenceType _selectedType = RecurrenceType.none;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await widget.onSubmit(title, description.isEmpty ? null : description, _selectedType);
    if (success && mounted) Navigator.pop(context);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
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
          Text(AppStrings.addTodo, style: theme.textTheme.titleLarge),
          AppSpacing.gapMd,

          // Title
          TextFormField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: AppStrings.todoTitle,
              prefixIcon: Icon(Icons.check_circle_outline),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapMd,

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: AppStrings.descriptionLabel,
              prefixIcon: Icon(Icons.description_outlined),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          AppSpacing.gapMd,

          // Recurrence picker
          Text(AppStrings.frequency, style: theme.textTheme.bodyMedium),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            children: RecurrenceType.values.map((type) {
              final selected = type == _selectedType;
              return ChoiceChip(
                label: Text(type.label),
                selected: selected,
                onSelected: (_) => setState(() => _selectedType = type),
              );
            }).toList(),
          ),
          AppSpacing.gapLg,

          // Submit
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.addTodo),
          ),
        ],
      ),
    );
  }
}
