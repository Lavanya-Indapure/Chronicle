import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.welcomeBack,
              style: theme.textTheme.headlineMedium,
            ),
            AppSpacing.gapSm,
            Text(
              AppStrings.dashboardSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            AppSpacing.gapXl,
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                children: const [
                  _QuickStatCard(
                    icon: Icons.check_circle_outline,
                    label: AppStrings.todosLabel,
                    value: '—',
                  ),
                  _QuickStatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: AppStrings.expensesLabel,
                    value: '—',
                  ),
                  _QuickStatCard(
                    icon: Icons.favorite_outline,
                    label: AppStrings.healthLabel,
                    value: '—',
                  ),
                  _QuickStatCard(
                    icon: Icons.trending_up,
                    label: AppStrings.streakLabel,
                    value: '—',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.paddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            AppSpacing.gapSm,
            Text(value, style: theme.textTheme.headlineSmall),
            AppSpacing.gapXs,
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
