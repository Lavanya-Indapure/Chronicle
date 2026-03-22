import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';

/// Reusable auth header with app name and tagline.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
        ),
        AppSpacing.gapLg,
        Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        AppSpacing.gapXs,
        Text(
          AppStrings.appTagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
