import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_strings.dart';

/// Main app shell with persistent bottom navigation bar.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        height: 64,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        // indicatorColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Colors.deepPurple),
            label: AppStrings.dashboardLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded, color: Colors.deepPurple),
            label: AppStrings.todosLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: Colors.deepPurple),
            label: AppStrings.expensesLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: Colors.deepPurple),
            label: AppStrings.healthLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: AppStrings.moreLabel,
          ),
        ],
      ),
    );
  }
}
