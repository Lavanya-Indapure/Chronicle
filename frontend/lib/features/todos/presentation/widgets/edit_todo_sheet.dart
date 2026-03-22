import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/core/widgets/chronicle_button.dart';

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

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
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
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            AppStrings.editTodo, 
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapLg,

          TextFormField(
            controller: _titleController,
            autofocus: true,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: AppStrings.todoTitle,
              prefixIcon: const Icon(Icons.edit_note_rounded),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapMd,

          TextFormField(
            controller: _descriptionController,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: AppStrings.descriptionLabel,
              prefixIcon: const Icon(Icons.notes_rounded),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          AppSpacing.gapLg,

          Text(
            AppStrings.frequency.toUpperCase(), 
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: RecurrenceType.values.map((type) {
              final selected = type == _selectedType;
              return FilterChip(
                label: Text(type.label),
                selected: selected,
                onSelected: (_) => setState(() => _selectedType = type),
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                side: BorderSide(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              );
            }).toList(),
          ),
          AppSpacing.gapXl,

          ChronicleButton(
            label: AppStrings.saveChanges,
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
            size: ChronicleButtonSize.lg,
          ),
        ],
      ),
    );
  }
}
