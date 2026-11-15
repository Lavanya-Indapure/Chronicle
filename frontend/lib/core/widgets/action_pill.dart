import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

/// Rounded quick-action chip with a small coloured icon dot
/// (e.g. "(+) Add Expense").
class ActionPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const ActionPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppSpacing.borderRadiusPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                child: Icon(icon, size: AppSpacing.md, color: theme.colorScheme.surface),
              ),
              AppSpacing.hGapSm,
              Text(label, style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
