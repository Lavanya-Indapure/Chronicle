import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

class HealthSettingsScreen extends StatelessWidget {
  const HealthSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const ListTile(
            title: Text('Hydration Reminders'),
            trailing: Switch(value: true, onChanged: null),
          ),
          ListTile(
            title: const Text('Reminder Interval'),
            subtitle: const Text('Every 60 minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Day Start Time'),
            subtitle: const Text('06:00 AM'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Day End Time'),
            subtitle: const Text('11:59 PM'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
