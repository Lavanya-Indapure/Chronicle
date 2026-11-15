import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/theme/app_colors.dart';

/// One destination in the [FloatingNavBar].
class FloatingNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const FloatingNavItem({required this.icon, required this.selectedIcon, required this.label});
}

/// Pill-shaped bottom navigation: round icon buttons, the selected one
/// filled in the inverse colour, plus a lemon action button at the end.
class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAction;
  final String actionLabel;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAction,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.sm),
        child: Container(
          height: AppSpacing.navItemSize + AppSpacing.navBarPadding * 2,
          padding: const EdgeInsets.all(AppSpacing.navBarPadding),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppSpacing.borderRadiusPill,
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: AppSpacing.lg, offset: Offset(0, AppSpacing.sm)),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavCircle(
                    icon: i == selectedIndex ? items[i].selectedIcon : items[i].icon,
                    label: items[i].label,
                    selected: i == selectedIndex,
                    background: i == selectedIndex ? colors.inverseSurface : colors.surfaceContainerHigh,
                    foreground: i == selectedIndex ? colors.onInverseSurface : colors.onSurfaceVariant,
                    onTap: () => onSelected(i),
                  ),
                ),
              Expanded(
                child: _NavCircle(
                  icon: Icons.add_rounded,
                  label: actionLabel,
                  selected: false,
                  background: colors.primaryContainer,
                  foreground: colors.onPrimaryContainer,
                  onTap: onAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _NavCircle({
    required this.icon,
    required this.label,
    required this.selected,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(0.0, AppSpacing.navItemSize) - 2;
        return Center(
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            excludeSemantics: true,
            child: Tooltip(
              message: label,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: size,
                height: size,
                decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                child: Material(
                  type: MaterialType.transparency,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Icon(icon, color: foreground, size: size * 0.46),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
