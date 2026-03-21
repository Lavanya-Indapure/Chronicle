import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/movies/presentation/controllers/movie_controller.dart';
import 'package:chronicle/features/movies/domain/models/movie.dart';

class AddMovieSheet extends ConsumerStatefulWidget {
  final Movie? movie;

  const AddMovieSheet({super.key, this.movie});

  @override
  ConsumerState<AddMovieSheet> createState() => _AddMovieSheetState();
}

class _AddMovieSheetState extends ConsumerState<AddMovieSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _commentsController = TextEditingController();
  final _takeawaysController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _platform = 'mobile-laptop';
  int _rating = 3;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.movie != null) {
      _nameController.text = widget.movie!.name;
      _selectedDate = widget.movie!.watchDate;
      _platform = widget.movie!.platform;
      _costController.text = widget.movie!.cost?.toString() ?? '';
      _rating = widget.movie!.rating;
      _commentsController.text = widget.movie!.comments ?? '';
      _takeawaysController.text = widget.movie!.takeaways ?? '';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final movie = Movie(
        id: widget.movie?.id ?? '',
        userId: widget.movie?.userId ?? '',
        name: _nameController.text.trim(),
        watchDate: _selectedDate,
        platform: _platform,
        rating: _rating,
        cost: _platform == 'theatre' ? double.tryParse(_costController.text) : null,
        comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
        takeaways: _takeawaysController.text.trim().isEmpty ? null : _takeawaysController.text.trim(),
      );

      if (widget.movie == null) {
        await ref.read(movieControllerProvider.notifier).createMovie(movie);
      } else {
        await ref.read(movieControllerProvider.notifier).updateMovie(widget.movie!.id, movie);
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
        title: const Text('Delete Log?'),
        content: const Text('Are you sure you want to remove this movie entry?'),
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
        await ref.read(movieControllerProvider.notifier).deleteMovie(widget.movie!.id);
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
                  Text(widget.movie == null ? 'Log Movie' : 'Edit Movie Log', style: theme.textTheme.titleLarge),
                  if (widget.movie != null)
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
                ],
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Movie Name', prefixIcon: Icon(Icons.movie_outlined)),
                validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
              ),
              AppSpacing.gapMd,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _platform,
                      decoration: const InputDecoration(labelText: 'Platform'),
                      items: const [
                        DropdownMenuItem(value: 'theatre', child: Text('🎭 Theatre')),
                        DropdownMenuItem(value: 'mobile-laptop', child: Text('📱 Digital')),
                      ],
                      onChanged: (v) => setState(() => _platform = v!),
                    ),
                  ),
                ],
              ),
              if (_platform == 'theatre') ...[
                AppSpacing.gapMd,
                TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(labelText: 'Cost (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                  keyboardType: TextInputType.number,
                  validator: (v) => _platform == 'theatre' && (v?.isEmpty ?? true) ? 'Cost is required for theatre' : null,
                ),
              ],
              AppSpacing.gapLg,
              Text('Rating', style: theme.textTheme.labelMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating ? Colors.amber : Colors.grey,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                )),
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _commentsController,
                decoration: const InputDecoration(labelText: 'Comments (Optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _takeawaysController,
                decoration: const InputDecoration(labelText: 'Takeaways (Optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              AppSpacing.gapLg,
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting ? const CircularProgressIndicator() : Text(widget.movie == null ? 'Save Log' : 'Update Log'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
