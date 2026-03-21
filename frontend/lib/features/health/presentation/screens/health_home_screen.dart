import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';

class HealthHomeScreen extends ConsumerWidget {
  const HealthHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydration = ref.watch(hydrationControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & Wellness'),
        actions: [
          IconButton(onPressed: () => context.push('/health/settings'), icon: const Icon(Icons.settings)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _HealthSummaryCard(hydration: hydration),
          AppSpacing.gapLg,
          Text('Daily Tracking', style: theme.textTheme.titleMedium),
          AppSpacing.gapMd,
          _HealthFeatureTile(
            title: 'Hydration',
            subtitle: '${hydration.doneReminders} / ${hydration.reminders.length} glasses',
            icon: Icons.water_drop,
            color: Colors.blue,
            onTap: () => context.push('/health/hydration'),
          ),
          _HealthFeatureTile(
            title: 'Sleep Tracking',
            subtitle: 'Last night: 7h 30m',
            icon: Icons.bedtime,
            color: Colors.indigo,
            onTap: () => context.push('/health/sleep'),
          ),
          _HealthFeatureTile(
            title: 'Physical Activity',
            subtitle: 'Coming Soon',
            icon: Icons.fitness_center,
            color: Colors.orange,
            onTap: () => context.push('/health/activity'),
          ),
        ],
      ),
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  final HydrationState hydration;
  const _HealthSummaryCard({required this.hydration});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text('Daily Goal Progress', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            AppSpacing.gapMd,
            LinearProgressIndicator(
              value: hydration.hydrationPercentage / 100,
              backgroundColor: theme.colorScheme.onPrimaryContainer.withOpacity(0.1),
              color: theme.colorScheme.onPrimaryContainer,
            ),
            AppSpacing.gapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hydration: ${hydration.hydrationPercentage.toInt()}%', style: theme.textTheme.labelSmall),
                Text('Sleep: 90%', style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthFeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HealthFeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
