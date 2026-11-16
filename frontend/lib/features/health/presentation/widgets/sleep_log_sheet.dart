import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/keyboard_aware_sheet.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/health/presentation/widgets/health_widgets.dart';

/// Opens the "log a night" sheet. [onSave] returns whether saving worked.
Future<void> showSleepLogSheet(
  BuildContext context, {
  required Future<bool> Function(DateTime start, DateTime end) onSave,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => SleepLogSheet(onSave: onSave),
  );
}

/// Manual entry for a night that wasn't tracked live.
class SleepLogSheet extends StatefulWidget {
  /// Longest session accepted, to catch AM/PM mix-ups.
  static const maxDuration = Duration(hours: 18);

  final Future<bool> Function(DateTime start, DateTime end) onSave;

  const SleepLogSheet({super.key, required this.onSave});

  @override
  State<SleepLogSheet> createState() => _SleepLogSheetState();
}

class _SleepLogSheetState extends State<SleepLogSheet> {
  late DateTime _start;
  late DateTime _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _end = today.add(const Duration(hours: 7));
    _start = today.subtract(const Duration(hours: 1)); // 23:00 yesterday
  }

  String? get _error {
    final length = _end.difference(_start);
    if (length <= Duration.zero) return AppStrings.sleepErrorOrder;
    if (length > SleepLogSheet.maxDuration) return AppStrings.sleepErrorTooLong;
    if (_end.isAfter(DateTime.now())) return AppStrings.sleepErrorFuture;
    return null;
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onSave(_start, _end);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;

    return KeyboardAwareSheet(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.sleepAddManual, style: theme.textTheme.titleLarge),
          AppSpacing.gapMd,
          _TimeField(
            icon: Icons.bedtime_rounded,
            label: AppStrings.sleepBedtime,
            value: _start,
            onTap: () async {
              final picked = await _pick(_start);
              if (picked != null) setState(() => _start = picked);
            },
          ),
          AppSpacing.gapSm,
          _TimeField(
            icon: Icons.wb_sunny_rounded,
            label: AppStrings.sleepWakeTime,
            value: _end,
            onTap: () async {
              final picked = await _pick(_end);
              if (picked != null) setState(() => _end = picked);
            },
          ),
          AppSpacing.gapMd,
          Text(
            error ?? '${AppStrings.sleepTotal}: ${AppFormatters.duration(_end.difference(_start))}',
            style: theme.textTheme.bodyMedium?.copyWith(color: error == null ? null : theme.colorScheme.error),
          ),
          AppSpacing.gapLg,
          FilledButton(
            onPressed: error != null || _saving ? null : _save,
            child: Text(_saving ? AppStrings.saving : AppStrings.save),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _TimeField({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: onTap,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          AppSpacing.hGapMd,
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '${AppFormatters.dayMonth(value)}, ${clockTime(context, value)}',
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
