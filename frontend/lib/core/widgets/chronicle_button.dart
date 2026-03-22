import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

enum ChronicleButtonSize { sm, md, lg }

/// A premium button widget for the Chronicle design system.
/// Wraps FilledButton and OutlinedButton with consistent sizing and style.
class ChronicleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final bool isOutlined;
  final ChronicleButtonSize size;
   final IconData? icon;
   final Color? color;

   const ChronicleButton({
     super.key,
     required this.label,
     this.onPressed,
     this.isLoading = false,
     this.isFullWidth = true,
     this.isOutlined = false,
     this.size = ChronicleButtonSize.md,
     this.icon,
     this.color,
   });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ButtonStyle style;
    if (isOutlined) {
      style = theme.outlinedButtonTheme.style!;
    } else {
      style = theme.filledButtonTheme.style!;
    }

    final verticalPadding = switch (size) {
      ChronicleButtonSize.sm => AppSpacing.xs,
      ChronicleButtonSize.md => AppSpacing.md,
      ChronicleButtonSize.lg => AppSpacing.lg,
    };

     style = style.copyWith(
       padding: WidgetStateProperty.all(
         EdgeInsets.symmetric(
           vertical: verticalPadding,
           horizontal: AppSpacing.lg,
         ),
       ),
       backgroundColor: color != null ? WidgetStateProperty.all(color) : null,
       foregroundColor: color != null ? WidgetStateProperty.all(Colors.white) : null,
     );

    Widget content = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                AppSpacing.hGapSm,
              ],
              Text(label),
            ],
          );

    if (isFullWidth) {
      content = SizedBox(
        width: double.infinity,
        child: Center(child: content),
      );
    }

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: content,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: content,
    );
  }
}
