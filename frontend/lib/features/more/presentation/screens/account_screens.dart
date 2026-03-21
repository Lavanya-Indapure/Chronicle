import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chronicle/core/theme/theme_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    final user = authRepo.currentUser;
    final metadata = user?.userMetadata ?? {};
    final firstName = metadata['first_name'] ?? 'User';
    final lastName = metadata['last_name'] ?? '';
    final email = user?.email ?? 'No email available';
    final createdAt = user?.createdAt ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
          ),
          AppSpacing.gapLg,
          Center(
            child: Text(
              '$firstName $lastName',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Center(
            child: Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          AppSpacing.gapXl,
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Member Since'),
            subtitle: Text(createdAt.split('T').first),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
          AppSpacing.gapSm,
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme Mode'),
            subtitle: Text(themeMode.name.toUpperCase()),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeControllerProvider.notifier).setThemeMode(mode);
                }
              },
              items: ThemeMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.name.toUpperCase()),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          AppSpacing.gapMd,
          const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
