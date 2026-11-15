import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';

// Small building blocks shared by the journaling screens (Learnings,
// First-times, Places, Moods, Thoughts). Candidates for core/widgets.

/// Sheet title with an optional delete action on the right.
class JournalSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onDelete;

  const JournalSheetHeader({super.key, required this.title, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (onDelete != null)
          IconButton(
            tooltip: AppStrings.delete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          ),
      ],
    );
  }
}

/// Tappable date row ("📅 Date ........ 22 Mar 2026") opening a date picker.
class JournalDateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const JournalDateField({super.key, this.label = AppStrings.journalDate, required this.value, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: AppSpacing.borderRadiusLg,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => _pick(context),
        leading: const Icon(Icons.calendar_today_outlined),
        title: Text(label),
        trailing: Text(AppFormatters.dayMonthYear(value), style: theme.textTheme.titleSmall),
      ),
    );
  }
}

/// Small tinted pill, e.g. a category or "#tag".
class TagPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const TagPill({super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs / 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppSpacing.borderRadiusPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.md - 2, color: color),
            AppSpacing.hGapXs,
          ],
          // Long tags shrink with an ellipsis instead of overflowing a
          // narrow Wrap/Row.
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Red swipe-to-delete background matching the rounded cards.
class DeleteSwipeBackground extends StatelessWidget {
  const DeleteSwipeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.error, borderRadius: AppSpacing.borderRadiusXl),
      child: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.onError),
    );
  }
}

/// "Delete entry?" confirmation. Returns true when confirmed.
Future<bool> confirmJournalDelete(BuildContext context, {String title = AppStrings.journalDeleteTitle}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: const Text(AppStrings.journalDeleteMessage),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text(AppStrings.delete),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Groups [items] under month headers ("November 2026"), newest first,
/// interleaving [header] and [item] widgets with standard spacing.
List<Widget> groupByMonth<T>({
  required List<T> items,
  required DateTime Function(T) dateOf,
  required Widget Function(String label) header,
  required Widget Function(T item) item,
}) {
  final sorted = [...items]..sort((a, b) => dateOf(b).compareTo(dateOf(a)));
  final out = <Widget>[];
  DateTime? current;
  for (final it in sorted) {
    final d = dateOf(it);
    final month = DateTime(d.year, d.month);
    if (month != current) {
      current = month;
      if (out.isNotEmpty) out.add(AppSpacing.gapLg);
      out
        ..add(header(AppFormatters.monthYear(month)))
        ..add(AppSpacing.gapSm);
    } else {
      out.add(AppSpacing.gapSm);
    }
    out.add(item(it));
  }
  return out;
}
