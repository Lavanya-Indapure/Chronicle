import 'package:flutter/material.dart';

/// Body for form bottom sheets.
///
/// Drop-in replacement for `Padding(padding: …viewInsets.bottom…, child: …)`:
/// the same [padding] (including the keyboard inset) is applied, but the
/// content scrolls instead of overflowing when the keyboard leaves too little
/// room, and the focused field is scrolled into view automatically.
///
/// Open the sheet with `isScrollControlled: true` so it can grow above the
/// default half-screen height.
class KeyboardAwareSheet extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const KeyboardAwareSheet({super.key, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: child,
    );
  }
}
