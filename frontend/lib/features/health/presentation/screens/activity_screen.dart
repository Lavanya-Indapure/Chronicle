import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_button.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center_rounded, 
                  size: 80, 
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              AppSpacing.gapXl,
              Text(
                'Activity Tracking', 
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.gapSm,
              Text(
                'We\'re building something special to help you track your physical wellness.', 
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapXl,
              ChronicleButton(
                label: 'Get Notified',
                onPressed: () {
                  // TODO: Follow or notify logic
                },
                icon: Icons.notifications_active_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
