import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';

/// Bottom sheet to edit a todo template.
class EditTodoSheet extends StatefulWidget {
  final String currentTitle;
  final String? currentDescription;
  final RecurrenceType currentType;
  final Future<bool> Function(String title, String? description, RecurrenceType type) onSubmit;

  const EditTodoSheet({
    super.key,
    required this.currentTitle,
    this.currentDescription,
    required this.currentType,
    required this.onSubmit,
  });

  @override
  State<EditTodoSheet> createState() => _EditTodoSheetState();
}

class _EditTodoSheetState extends State<EditTodoSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late RecurrenceType _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _descriptionController = TextEditingController(text: widget.currentDescription);
    _selectedType = widget.currentType;
  }

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
    final success = await widget.onSubmit(
      title,
      description.isEmpty ? null : description,
      _selectedType,
    );
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
          Text(AppStrings.editTodo, style: theme.textTheme.titleLarge),
          AppSpacing.gapMd,

          TextFormField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: AppStrings.todoTitle,
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapMd,

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

          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.saveChanges),
          ),
        ],
      ),
    );
  }
}
