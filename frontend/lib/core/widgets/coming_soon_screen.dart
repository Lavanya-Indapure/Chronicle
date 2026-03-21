import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';

/// Reusable "Coming Soon" placeholder screen.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            AppSpacing.gapMd,
            Text(AppStrings.comingSoon, style: theme.textTheme.titleMedium),
            AppSpacing.gapSm,
            Text(
              '$title will be available soon',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
