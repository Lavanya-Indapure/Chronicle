import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_outlined, size: 64),
            AppSpacing.gapMd,
            Text('Activity Module In Development', style: theme.textTheme.titleMedium),
            Text('Coming in the next update!', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
