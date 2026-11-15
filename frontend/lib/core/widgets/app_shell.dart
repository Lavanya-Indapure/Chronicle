import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/floating_nav_bar.dart';
import 'package:chronicle/core/widgets/quick_add_sheet.dart';

/// Main app shell with the floating pill navigation bar.
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _items = [
    FloatingNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: AppStrings.dashboardLabel,
    ),
    FloatingNavItem(
      icon: Icons.check_circle_outline_rounded,
      selectedIcon: Icons.check_circle_rounded,
      label: AppStrings.todosLabel,
    ),
    FloatingNavItem(
      icon: Icons.bar_chart_rounded,
      selectedIcon: Icons.bar_chart_rounded,
      label: AppStrings.expensesLabel,
    ),
    FloatingNavItem(
      icon: Icons.favorite_outline_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: AppStrings.healthLabel,
    ),
    FloatingNavItem(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: AppStrings.moreLabel,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: FloatingNavBar(
        items: _items,
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        actionLabel: AppStrings.quickAdd,
        onAction: () => showQuickAddSheet(context, ref),
      ),
    );
  }
}
