import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';

/// Centered empty / no-results state: lemon icon badge, title, message and an
/// optional call-to-action button.
///
/// Use [muted] for "no results for this search/filter" so it reads as a
/// neutral notice rather than an invitation to create something.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool muted;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(
              icon: icon,
              color: muted ? colors.surfaceContainerHigh : colors.primaryContainer,
              onColor: muted ? colors.onSurfaceVariant : colors.onPrimaryContainer,
              filled: true,
              size: AppSpacing.xxxl,
            ),
            AppSpacing.gapLg,
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            AppSpacing.gapXs,
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null && !muted) ...[
              AppSpacing.gapLg,
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
