import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/thoughts/presentation/controllers/thought_controller.dart';
import 'package:chronicle/features/thoughts/domain/models/thought.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';

class AddThoughtSheet extends ConsumerStatefulWidget {
  final Thought? thought;

  const AddThoughtSheet({super.key, this.thought});

  @override
  ConsumerState<AddThoughtSheet> createState() => _AddThoughtSheetState();
}

class _AddThoughtSheetState extends ConsumerState<AddThoughtSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.thought != null) {
      _contentController.text = widget.thought!.content;
      _tagsController.text = widget.thought!.tags ?? '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.thought == null) {
        await ref.read(thoughtControllerProvider.notifier).createThought(
          _contentController.text.trim(),
          _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
        );
      } else {
        await ref.read(thoughtControllerProvider.notifier).updateThought(
          widget.thought!.id,
          _contentController.text.trim(),
          _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Thought?'),
        content: const Text('Are you sure you want to remove this insight?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      try {
        await ref.read(thoughtControllerProvider.notifier).deleteThought(widget.thought!.id);
        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.thought == null ? 'Capture Thought' : 'Edit Thought', style: theme.textTheme.titleLarge),
                if (widget.thought != null)
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
              ],
            ),
            AppSpacing.gapLg,
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Quote or Idea',
                hintText: 'What is on your mind?',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (v) => v?.isEmpty ?? true ? 'Content is required' : null,
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'motivation, life, deep',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            AppSpacing.gapLg,
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting ? const CircularProgressIndicator() : Text(widget.thought == null ? 'Save Insight' : 'Update Insight'),
            ),
          ],
        ),
      ),
    );
  }
}
