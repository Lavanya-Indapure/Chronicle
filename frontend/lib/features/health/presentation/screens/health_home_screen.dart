import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';
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
          IconButton(
            onPressed: () => context.push('/health/settings'), 
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _HealthSummaryCard(hydration: hydration),
          AppSpacing.gapLg,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'DAILY TRACKING'.toUpperCase(), 
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          AppSpacing.gapMd,
          _HealthFeatureTile(
            title: 'Hydration',
            subtitle: '${hydration.doneReminders} / ${hydration.reminders.length} glasses',
            icon: Icons.water_drop_rounded,
            color: Colors.blue,
            onTap: () => context.push('/health/hydration'),
          ),
          _HealthFeatureTile(
            title: 'Sleep Tracking',
            subtitle: 'Last night: 7h 30m',
            icon: Icons.bedtime_rounded,
            color: Colors.indigo,
            onTap: () => context.push('/health/sleep'),
          ),
          _HealthFeatureTile(
            title: 'Physical Activity',
            subtitle: 'Coming Soon',
            icon: Icons.fitness_center_rounded,
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
    final primaryColor = theme.colorScheme.primary;

    return ChronicleCard(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 20, color: primaryColor),
              AppSpacing.gapSm,
              Text(
                'Daily Goal Progress', 
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.gapLg,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: hydration.hydrationPercentage / 100,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              color: primaryColor,
              minHeight: 12,
            ),
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  label: 'Hydration',
                  value: '${hydration.hydrationPercentage.toInt()}%',
                  icon: Icons.water_drop_rounded,
                  color: Colors.blue,
                ),
              ),
              Container(width: 1, height: 24, color: theme.colorScheme.outlineVariant),
              Expanded(
                child: _SmallMetric(
                  label: 'Sleep',
                  value: '90%',
                  icon: Icons.bedtime_rounded,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SmallMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            AppSpacing.gapXs,
            Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ChronicleCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title, 
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded, 
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
