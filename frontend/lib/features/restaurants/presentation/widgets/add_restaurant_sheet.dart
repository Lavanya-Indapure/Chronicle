import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';

class AddRestaurantSheet extends ConsumerStatefulWidget {
  const AddRestaurantSheet({super.key});

  @override
  ConsumerState<AddRestaurantSheet> createState() => _AddRestaurantSheetState();
}

class _AddRestaurantSheetState extends ConsumerState<AddRestaurantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _billController = TextEditingController();
  final _foodController = TextEditingController();
  final _notesController = TextEditingController();
  
  double _rating = 3.0;
  bool _isFavorite = false;
  final List<File> _photos = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

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
      await ref.read(restaurantControllerProvider.notifier).createRestaurant(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        rating: _rating,
        billAmount: double.tryParse(_billController.text),
        foodItems: _foodController.text.trim().isEmpty ? null : _foodController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        photos: _photos,
        isFavorite: _isFavorite,
      );
      if (mounted) Navigator.pop(context);
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
              Text('Log Restaurant', style: theme.textTheme.titleLarge),
              AppSpacing.gapLg,

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Restaurant Name', prefixIcon: Icon(Icons.restaurant)),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              AppSpacing.gapMd,

              Row(
                children: [
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rating: ${_rating.toStringAsFixed(1)}', style: theme.textTheme.titleSmall),
                        Slider(
                          value: _rating,
                          min: 1,
                          max: 5,
                          divisions: 8,
                          onChanged: (v) => setState(() => _rating = v),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(),
                  Switch.adaptive(
                    value: _isFavorite,
                    onChanged: (v) => setState(() => _isFavorite = v),
                    activeThumbColor: Colors.red,
                  ),
                  const Icon(Icons.favorite, color: Colors.red),
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
                      decoration: const InputDecoration(labelText: 'Special/Items', prefixIcon: Icon(Icons.flatware_outlined)),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)),
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
                child: _isSubmitting ? const CircularProgressIndicator() : const Text('Save Restaurant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
