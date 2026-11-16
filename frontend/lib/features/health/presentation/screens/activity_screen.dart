import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/health/domain/health_stats.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/health/presentation/widgets/health_widgets.dart';

const exerciseColor = AppColors.chartOrange;
const meditationColor = AppColors.chartOrchid;

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityControllerProvider);
    final controller = ref.read(activityControllerProvider.notifier);
    ref.listen(activityControllerProvider, (prev, next) => showHealthError(context, prev?.errorMessage, next.errorMessage));
    final today = state.today;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.activityTitle)),
      body: state.isLoading && state.logs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
                children: [
                  SectionHeader(title: AppStrings.activityToday, subtitle: AppFormatters.weekdayDayMonth(DateTime.now()), compact: true),
                  AppSpacing.gapSm,
                  Row(
                    children: [
                      Expanded(
                        child: _ActivityToggleCard(
                          icon: Icons.fitness_center_rounded,
                          color: exerciseColor,
                          label: AppStrings.activityExercise,
                          done: today.exerciseDone,
                          streak: state.exerciseStreak,
                          onTap: controller.toggleExercise,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: _ActivityToggleCard(
                          icon: Icons.self_improvement_rounded,
                          color: meditationColor,
                          label: AppStrings.activityMeditation,
                          done: today.meditationDone,
                          streak: state.meditationStreak,
                          onTap: controller.toggleMeditation,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  // Keyed by the stored note so the field resets when today's
                  // log loads or the day changes.
                  _NotesCard(key: ValueKey('${today.logDate}|${today.notes}'), initial: today.notes ?? '', onSave: controller.saveNotes),
                  AppSpacing.gapLg,
                  const SectionHeader(title: AppStrings.activityLastFourWeeks, compact: true),
                  AppSpacing.gapSm,
                  _HistoryCard(state: state),
                ],
              ),
            ),
    );
  }
}

class _ActivityToggleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool done;
  final int streak;
  final VoidCallback onTap;

  const _ActivityToggleCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.done,
    required this.streak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fg = done ? colors.surface : colors.onSurface;

    return Semantics(
      toggled: done,
      button: true,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(color: done ? color : colors.surface, borderRadius: AppSpacing.borderRadiusXl),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppSpacing.borderRadiusXl,
            onTap: onTap,
            child: Padding(
              padding: AppSpacing.paddingCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: done ? fg : color),
                      const Spacer(),
                      Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: done ? fg : colors.onSurfaceVariant),
                    ],
                  ),
                  AppSpacing.gapMd,
                  Text(label, style: theme.textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w600)),
                  Text(
                    done ? AppStrings.activityDoneToday : AppStrings.activityTapToLog,
                    style: theme.textTheme.bodySmall?.copyWith(color: done ? fg : null),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    '$streak ${streak == 1 ? AppStrings.activityDayStreak : AppStrings.activityDaysStreak}',
                    style: theme.textTheme.labelMedium?.copyWith(color: done ? fg : color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends StatefulWidget {
  final String initial;
  final Future<bool> Function(String) onSave;

  const _NotesCard({super.key, required this.initial, required this.onSave});

  @override
  State<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<_NotesCard> {
  late final TextEditingController _text = TextEditingController(text: widget.initial);
  bool _dirty = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (await widget.onSave(_text.text) && mounted) setState(() => _dirty = false);
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _text,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: AppStrings.activityNotesHint),
            onChanged: (v) {
              final dirty = v.trim() != widget.initial.trim();
              if (dirty != _dirty) setState(() => _dirty = dirty);
            },
          ),
          if (_dirty) ...[
            AppSpacing.gapSm,
            FilledButton(onPressed: _save, child: const Text(AppStrings.save)),
          ],
        ],
      ),
    );
  }
}

/// 4-week grid per activity: one row per week (oldest first), one square
/// per day.
class _HistoryCard extends StatelessWidget {
  static const _weeks = 4;

  final ActivityState state;

  const _HistoryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final today = HealthStats.day(DateTime.now());
    // Start on the Monday [_weeks - 1] weeks before this week's Monday.
    final start = today.subtract(Duration(days: today.weekday - 1 + 7 * (_weeks - 1)));
    final days = [for (var i = 0; i < 7 * _weeks; i++) start.add(Duration(days: i))];

    return SurfaceCard(
      child: Column(
        children: [
          _HistoryRow(label: AppStrings.activityExercise, color: exerciseColor, days: days, today: today, isDone: (d) => state.logFor(d)?.exerciseDone ?? false),
          AppSpacing.gapMd,
          _HistoryRow(label: AppStrings.activityMeditation, color: meditationColor, days: days, today: today, isDone: (d) => state.logFor(d)?.meditationDone ?? false),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String label;
  final Color color;
  final List<DateTime> days;
  final DateTime today;
  final bool Function(DateTime) isDone;

  const _HistoryRow({required this.label, required this.color, required this.days, required this.today, required this.isDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count = days.where(isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            Text('$count ${AppStrings.activityDaysOutOf} ${days.where((d) => !d.isAfter(today)).length}', style: theme.textTheme.bodySmall),
          ],
        ),
        AppSpacing.gapSm,
        Semantics(
          label: '$label: $count ${AppStrings.activityDaysOutOf} ${days.length}',
          excludeSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.xs;
              final size = (constraints.maxWidth - gap * 6) / 7;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final d in days)
                    Container(
                      width: size,
                      height: size.clamp(0, AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: d.isAfter(today)
                            ? colors.surfaceContainerHighest.withValues(alpha: 0.4)
                            : isDone(d)
                                ? color
                                : colors.surfaceContainerHighest,
                        borderRadius: AppSpacing.borderRadiusSm,
                        border: d == today ? Border.all(color: colors.onSurface, width: 1.5) : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
