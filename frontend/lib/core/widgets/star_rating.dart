import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';

/// Read-only row of five stars (shared by Books and Movies).
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;

  const StarRatingDisplay({super.key, required this.rating, this.size = AppSpacing.md});

  @override
  Widget build(BuildContext context) {
    final empty = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.35);
    return Semantics(
      label: '${rating.toStringAsFixed(0)} / 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              rating >= i ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: rating >= i ? AppColors.chartLemon : empty,
            ),
        ],
      ),
    );
  }
}

/// Tappable 1–5 star picker. With [allowClear], tapping the current rating
/// again clears it (value becomes null).
class StarRatingPicker extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool allowClear;

  const StarRatingPicker({super.key, required this.value, required this.onChanged, this.allowClear = false});

  @override
  Widget build(BuildContext context) {
    final empty = Theme.of(context).colorScheme.onSurfaceVariant;
    final current = value ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i',
            iconSize: AppSpacing.xl,
            onPressed: () => onChanged(allowClear && i == current ? null : i),
            icon: Icon(
              current >= i ? Icons.star_rounded : Icons.star_outline_rounded,
              color: current >= i ? AppColors.chartLemon : empty,
            ),
          ),
        if (allowClear && value != null)
          IconButton(
            tooltip: AppStrings.clearRating,
            onPressed: () => onChanged(null),
            icon: Icon(Icons.close_rounded, color: empty),
          ),
      ],
    );
  }
}

/// "Usefulness · 3/5" label with five tappable stars.
class StarRatingInput extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const StarRatingInput({super.key, required this.label, required this.value, required this.onChanged});

  static const _max = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md - 4, AppSpacing.md, AppSpacing.xs),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh, borderRadius: AppSpacing.borderRadiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              Text('$value/$_max', style: theme.textTheme.titleSmall),
            ],
          ),
          // Stars share the full width so they stay large tap targets on
          // narrow phones.
          Row(
            children: [
              for (var i = 1; i <= _max; i++)
                Expanded(
                  child: IconButton(
                    tooltip: '$i/$_max',
                    onPressed: () => onChanged(i),
                    icon: Icon(
                      i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: AppSpacing.xl,
                      color: i <= value ? AppColors.chartLemon : theme.colorScheme.onSurfaceVariant,
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

