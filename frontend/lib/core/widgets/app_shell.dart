import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/floating_nav_bar.dart';
import 'package:chronicle/core/widgets/quick_add_sheet.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/reminders/presentation/controllers/reminder_sync_controller.dart';

/// Main app shell with the floating pill navigation bar. Shown only when
/// signed in, so it also keeps local reminders in sync with the user's data.
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final sync = ref.read(reminderSyncProvider);
    // Water reminders follow the saved health settings (once loaded).
    ref.listenManual(healthSettingsProvider, (_, next) {
      if (!next.isLoading) sync.syncHydration(next.settings);
    }, fireImmediately: true);
    // Dues change elsewhere; refresh the weekly nudge on start and resume.
    WidgetsBinding.instance.addPostFrameCallback((_) => sync.syncDues());
    _lifecycle = AppLifecycleListener(onResume: sync.syncDues);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ShellScaffold(navigationShell: widget.navigationShell);
}

class _ShellScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _ShellScaffold({required this.navigationShell});

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
