import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

/// Pill-shaped search box used at the top of list screens.
class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const AppSearchField({super.key, required this.hint, required this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    OutlineInputBorder border([BorderSide side = BorderSide.none]) =>
        OutlineInputBorder(borderRadius: AppSpacing.borderRadiusPill, borderSide: side);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        fillColor: colors.surface,
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(BorderSide(color: colors.primary, width: 1.5)),
      ),
    );
  }
}
