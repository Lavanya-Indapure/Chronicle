import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';
import 'package:chronicle/features/restaurants/presentation/widgets/restaurant_form_fields.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _billController.dispose();
    _foodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _trimmedOrNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? AppStrings.fieldRequired : null;

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() => _photos.addAll(pickedFiles.map((f) => File(f.path))));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final ok = await ref.read(restaurantControllerProvider.notifier).createRestaurant(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          rating: _rating,
          billAmount: double.tryParse(_billController.text.trim()),
          foodItems: _trimmedOrNull(_foodController),
          notes: _trimmedOrNull(_notesController),
          photos: _photos,
          isFavorite: _isFavorite,
        );
    if (!mounted) return;
    // On failure the screen shows the error; keep the sheet open to retry.
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardAwareSheet(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.logRestaurant, style: theme.textTheme.titleLarge),
            AppSpacing.gapLg,
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.restaurantName,
                prefixIcon: Icon(Icons.restaurant_rounded),
              ),
              validator: _required,
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _addressController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.address,
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: _required,
            ),
            AppSpacing.gapMd,
            RatingField(label: AppStrings.ratingLabel, value: _rating, onChanged: (v) => setState(() => _rating = v)),
            AppSpacing.gapMd,
            FavouriteToggle(value: _isFavorite, onChanged: (v) => setState(() => _isFavorite = v)),
            AppSpacing.gapMd,
            TextFormField(
              controller: _billController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.billAmount,
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _foodController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.whatYouAte,
                prefixIcon: Icon(Icons.restaurant_menu_rounded),
              ),
            ),
            AppSpacing.gapMd,
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: AppStrings.notesLabel,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            AppSpacing.gapMd,
            PhotoPickerStrip(
              photos: _photos,
              onAdd: _pickImages,
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
            AppSpacing.gapLg,
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(dimension: AppSpacing.md + 4, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(AppStrings.saveRestaurant),
            ),
          ],
        ),
      ),
    );
  }
}
