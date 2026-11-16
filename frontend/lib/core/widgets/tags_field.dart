import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_strings.dart';

/// Comma-separated tags input used by every taggable form. Parse the text
/// with `TagUtils.parse` on save.
class TagsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const TagsField({
    super.key,
    required this.controller,
    this.label = AppStrings.tagsLabel,
    this.hint = AppStrings.tagsHint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.tag_rounded),
      ),
    );
  }
}
