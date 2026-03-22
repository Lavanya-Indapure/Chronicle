import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/books/presentation/controllers/book_controller.dart';
import 'package:chronicle/features/books/domain/models/book.dart';

class AddBookSheet extends ConsumerStatefulWidget {
  final Book? book;

  const AddBookSheet({super.key, this.book});

  @override
  ConsumerState<AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends ConsumerState<AddBookSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authorController = TextEditingController();
  final _takeawaysController = TextEditingController();
  
  String _status = 'reading';
  double? _rating;
  bool _isFavorite = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _nameController.text = widget.book!.name;
      _authorController.text = widget.book!.author ?? '';
      _takeawaysController.text = widget.book!.takeaways ?? '';
      _status = widget.book!.status;
      _rating = widget.book!.rating;
      _isFavorite = widget.book!.isFavorite;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.book == null) {
        await ref.read(bookControllerProvider.notifier).createBook(
          name: _nameController.text.trim(),
          author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
          takeaways: _takeawaysController.text.trim().isEmpty ? null : _takeawaysController.text.trim(),
          status: _status,
          rating: _rating,
          isFavorite: _isFavorite,
        );
      } else {
        await ref.read(bookControllerProvider.notifier).updateBook(
          id: widget.book!.id,
          name: _nameController.text.trim(),
          author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
          takeaways: _takeawaysController.text.trim().isEmpty ? null : _takeawaysController.text.trim(),
          status: _status,
          rating: _rating,
          isFavorite: _isFavorite,
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
        title: const Text('Remove Book?'),
        content: const Text('Are you sure you want to delete this book from your library?'),
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
        await ref.read(bookControllerProvider.notifier).deleteBook(widget.book!.id);
        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.book == null ? 'Add New Book' : 'Edit Book Details', style: theme.textTheme.titleLarge),
                  if (widget.book != null)
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
                ],
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Book Title', prefixIcon: Icon(Icons.book)),
                validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author (optional)', prefixIcon: Icon(Icons.person_outline)),
              ),
              AppSpacing.gapMd,
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'reading', child: Text('📖 Reading')),
                        DropdownMenuItem(value: 'completed', child: Text('✅ Completed')),
                      ],
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ),
                  AppSpacing.gapMd,
                   Expanded(
                    child: DropdownButtonFormField<double?>(
                      initialValue: _rating,
                      decoration: const InputDecoration(labelText: 'Rating'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Rating')),
                        ...[1, 2, 3, 4, 5].map((e) => DropdownMenuItem(value: e.toDouble(), child: Text('⭐ $e'))),
                      ],
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,

              TextFormField(
                controller: _takeawaysController,
                decoration: const InputDecoration(
                  labelText: 'Key Takeaways',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              AppSpacing.gapMd,

              SwitchListTile.adaptive(
                title: const Text('Mark as Favorite'),
                value: _isFavorite,
                onChanged: (v) => setState(() => _isFavorite = v),
                secondary: const Icon(Icons.favorite, color: Colors.red),
              ),

              AppSpacing.gapLg,
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting ? const CircularProgressIndicator() : Text(widget.book == null ? 'Add to Library' : 'Update Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
