import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';

/// "‹  November 2026  ›" — arrows step one month; tapping the label opens a
/// year + month grid to jump straight to any month in [firstMonth]–[lastMonth].
class MonthSwitcher extends StatelessWidget {
  final DateTime month;
  final DateTime firstMonth;
  final DateTime lastMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const MonthSwitcher({
    super.key,
    required this.month,
    required this.firstMonth,
    required this.lastMonth,
    required this.onMonthSelected,
  });

  bool get _canGoBack => month.isAfter(firstMonth);
  bool get _canGoForward => month.isBefore(lastMonth);

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => _MonthPickerSheet(selected: month, firstMonth: firstMonth, lastMonth: lastMonth),
    );
    if (picked != null) onMonthSelected(picked);
  }

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
            onPressed: _canGoBack ? () => onMonthSelected(DateTime(month.year, month.month - 1)) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Tooltip(
              message: AppStrings.pickMonth,
              child: InkWell(
                borderRadius: AppSpacing.borderRadiusPill,
                onTap: () => _openPicker(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            AppFormatters.monthYear(month),
                            key: ValueKey(month),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      AppSpacing.hGapXs,
                      Icon(Icons.expand_more_rounded, size: AppSpacing.md + 4, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.nextMonth,
            onPressed: _canGoForward ? () => onMonthSelected(DateTime(month.year, month.month + 1)) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Year stepper + 4×3 month grid. Pops with the chosen month.
class _MonthPickerSheet extends StatefulWidget {
  final DateTime selected;
  final DateTime firstMonth;
  final DateTime lastMonth;

  const _MonthPickerSheet({required this.selected, required this.firstMonth, required this.lastMonth});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year = widget.selected.year;

  bool _isEnabled(DateTime m) => !m.isBefore(widget.firstMonth) && !m.isAfter(widget.lastMonth);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isViewingLast = widget.selected == widget.lastMonth;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year stepper
            Row(
              children: [
                IconButton(
                  tooltip: AppStrings.previousYear,
                  onPressed: _year > widget.firstMonth.year ? () => setState(() => _year--) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text('$_year', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: AppStrings.nextYear,
                  onPressed: _year < widget.lastMonth.year ? () => setState(() => _year++) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            AppSpacing.gapMd,
            // Month grid
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.6,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    label: AppFormatters.shortMonth(DateTime(_year, m)),
                    selected: widget.selected == DateTime(_year, m),
                    enabled: _isEnabled(DateTime(_year, m)),
                    onTap: () => Navigator.pop(context, DateTime(_year, m)),
                  ),
              ],
            ),
            if (!isViewingLast) ...[
              AppSpacing.gapMd,
              TextButton.icon(
                onPressed: () => Navigator.pop(context, widget.lastMonth),
                icon: Icon(Icons.today_rounded, color: colors.primary),
                label: const Text(AppStrings.thisMonthShortcut),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _MonthCell({required this.label, required this.selected, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = selected ? colors.primaryContainer : colors.surfaceContainerHigh;
    final foreground = selected
        ? colors.onPrimaryContainer
        : enabled
            ? colors.onSurface
            : colors.onSurfaceVariant.withValues(alpha: 0.4);

    return Material(
      color: enabled || selected ? background : background.withValues(alpha: 0.4),
      borderRadius: AppSpacing.borderRadiusPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
