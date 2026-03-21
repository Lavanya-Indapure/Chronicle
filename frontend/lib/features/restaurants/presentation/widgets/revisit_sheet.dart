import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';

class RevisitSheet extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  final VoidCallback? onLogged;

  const RevisitSheet({super.key, required this.restaurant, this.onLogged});

  @override
  ConsumerState<RevisitSheet> createState() => _RevisitSheetState();
}

class _RevisitSheetState extends ConsumerState<RevisitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _billController = TextEditingController();
  final _foodController = TextEditingController();
  final _notesController = TextEditingController();
  
  double _rating = 3.0;
  final List<File> _photos = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _rating = widget.restaurant.rating;
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() => _photos.addAll(pickedFiles.map((f) => File(f.path))));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(restaurantControllerProvider.notifier).logRevisit(
        restaurantId: widget.restaurant.id,
        rating: _rating,
        billAmount: double.tryParse(_billController.text),
        foodItems: _foodController.text.trim().isEmpty ? null : _foodController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        photos: _photos,
      );
      if (mounted) {
        widget.onLogged?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revisit logged successfully!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
              Text('Log New Visit: ${widget.restaurant.name}', style: theme.textTheme.titleLarge),
              AppSpacing.gapLg,

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rating for this visit: ${_rating.toStringAsFixed(1)}', style: theme.textTheme.titleSmall),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                ],
              ),
              AppSpacing.gapMd,

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _billController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bill Amount', prefixText: '₹'),
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: TextFormField(
                      controller: _foodController,
                      decoration: const InputDecoration(labelText: 'Food/Items', prefixIcon: Icon(Icons.flatware_outlined)),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Visit Notes', prefixIcon: Icon(Icons.notes)),
                maxLines: 2,
              ),
              AppSpacing.gapMd,

              // Photo Picker
              Text('Photos (${_photos.length})', style: theme.textTheme.titleSmall),
              AppSpacing.gapSm,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      onTap: _pickImages,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    ),
                    ..._photos.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              child: Image.file(entry.value, width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _photos.removeAt(entry.key)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              AppSpacing.gapLg,

              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting ? const CircularProgressIndicator() : const Text('Log Revisit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
