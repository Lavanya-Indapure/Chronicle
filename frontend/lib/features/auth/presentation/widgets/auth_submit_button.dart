import 'package:flutter/material.dart';
import 'package:chronicle/core/widgets/chronicle_button.dart';

/// Reusable submit button for auth screens.
/// Features a loading state and full-width layout.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthSubmitButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChronicleButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      size: ChronicleButtonSize.lg,
    );
  }
}
