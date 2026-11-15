import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

/// Segmented pill control with a sliding indicator
/// (e.g. "Today | This Week | This Month").
class PillTabs<T> extends StatelessWidget {
  final List<T> values;
  final String Function(T value) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  const PillTabs({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  static const _duration = Duration(milliseconds: 220);
  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Dark: selected pill sinks into the background (as in the reference);
    // Light: selected pill is solid ink for contrast.
    final indicatorColor = isDark ? colors.surfaceContainerLowest : colors.primary;
    final selectedText = isDark ? colors.onSurface : colors.onPrimary;
    final selectedIndex = values.indexOf(selected).clamp(0, values.length - 1);

    return Container(
      height: _height,
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      decoration: BoxDecoration(color: colors.surface, borderRadius: AppSpacing.borderRadiusPill),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: _duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment(
              values.length == 1 ? 0 : -1 + 2 * selectedIndex / (values.length - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / values.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: indicatorColor, borderRadius: AppSpacing.borderRadiusPill),
              ),
            ),
          ),
          Row(
            children: [
              for (final value in values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: value == selected,
                    child: InkWell(
                      borderRadius: AppSpacing.borderRadiusPill,
                      onTap: () => onChanged(value),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: _duration,
                          style: theme.textTheme.labelMedium!.copyWith(
                            color: value == selected ? selectedText : colors.onSurfaceVariant,
                            fontWeight: value == selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          child: Text(labelOf(value), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
