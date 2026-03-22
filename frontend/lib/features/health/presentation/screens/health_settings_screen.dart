import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';

class HealthSettingsScreen extends StatelessWidget {
  const HealthSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Health Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
            child: Text(
              'HYDRATION SETTINGS'.toUpperCase(), 
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          ChronicleCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Hydration Reminders', 
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Get notified to drink water'),
                  value: true, 
                  onChanged: (val) {
                    // TODO: Implementation for toggle
                  },
                ),
                const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                _SettingsTile(
                  title: 'Reminder Interval',
                  subtitle: 'Every 60 minutes',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                _SettingsTile(
                  title: 'Day Start Time',
                  subtitle: '06:00 AM',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                _SettingsTile(
                  title: 'Day End Time',
                  subtitle: '11:59 PM',
                  onTap: () {},
                  isLast: true,
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
            child: Text(
              'SLEEP SETTINGS'.toUpperCase(), 
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          ChronicleCard(
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              title: 'Sleep Target',
              subtitle: '8 hours',
              onTap: () {},
              isLast: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        title, 
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right_rounded, 
        color: theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}
