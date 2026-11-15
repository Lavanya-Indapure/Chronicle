import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/features/restaurants/domain/models/restaurant.dart';
import 'package:chronicle/features/restaurants/presentation/controllers/restaurant_controller.dart';
import 'package:chronicle/features/restaurants/presentation/widgets/restaurant_form_fields.dart';

/// Logs another visit to an existing restaurant.
class RevisitSheet extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  final VoidCallback? onLogged;

  const RevisitSheet({super.key, required this.restaurant, this.onLogged});

  @override
  ConsumerState<RevisitSheet> createState() => _RevisitSheetState();
}

class _RevisitSheetState extends ConsumerState<RevisitSheet> {
  final _billController = TextEditingController();
  final _foodController = TextEditingController();
  final _notesController = TextEditingController();

  late double _rating = widget.restaurant.rating.clamp(1.0, 5.0);
  final List<File> _photos = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _billController.dispose();
    _foodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _trimmedOrNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() => _photos.addAll(pickedFiles.map((f) => File(f.path))));
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final ok = await ref.read(restaurantControllerProvider.notifier).logRevisit(
          restaurantId: widget.restaurant.id,
          rating: _rating,
          billAmount: double.tryParse(_billController.text.trim()),
          foodItems: _trimmedOrNull(_foodController),
          notes: _trimmedOrNull(_notesController),
          photos: _photos,
        );
    if (!mounted) return;
    if (!ok) {
      // The screen shows the error; keep the sheet open to retry.
      setState(() => _isSubmitting = false);
      return;
    }
    widget.onLogged?.call();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text(AppStrings.visitLogged)));
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.newVisitTo, style: theme.textTheme.bodyMedium),
          Text(
            widget.restaurant.name,
            style: theme.textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          AppSpacing.gapLg,
          RatingField(label: AppStrings.ratingForVisit, value: _rating, onChanged: (v) => setState(() => _rating = v)),
          AppSpacing.gapMd,
          TextField(
            controller: _billController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: AppStrings.billAmount,
              prefixIcon: Icon(Icons.currency_rupee_rounded),
            ),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _foodController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: AppStrings.whatYouAte,
              prefixIcon: Icon(Icons.restaurant_menu_rounded),
            ),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: AppStrings.visitNotes,
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
                : const Text(AppStrings.logVisit),
          ),
        ],
      ),
    );
  }
}
