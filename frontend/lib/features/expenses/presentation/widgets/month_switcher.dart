import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';

/// "‹  November 2026  ›" — steps the viewed month back and forth.
/// A null callback disables that arrow.
class MonthSwitcher extends StatelessWidget {
  final DateTime month;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const MonthSwitcher({super.key, required this.month, this.onPrevious, this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: AppSpacing.borderRadiusPill),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.previousMonth,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                AppFormatters.monthYear(month),
                key: ValueKey(month),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.nextMonth,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
