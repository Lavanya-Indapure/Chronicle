import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/health/presentation/widgets/health_widgets.dart';
import 'package:chronicle/features/health/presentation/widgets/sleep_chart_card.dart';
import 'package:chronicle/features/health/presentation/widgets/sleep_log_sheet.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepControllerProvider);
    final goal = ref.watch(healthSettingsProvider.select((s) => s.settings.sleepGoalHours));
    final controller = ref.read(sleepControllerProvider.notifier);
    ref.listen(sleepControllerProvider, (prev, next) => showHealthError(context, prev?.errorMessage, next.errorMessage));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.sleep),
        actions: [
          IconButton(
            tooltip: AppStrings.sleepAddManual,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showSleepLogSheet(context, onSave: controller.addSleep),
          ),
        ],
      ),
      body: state.isLoading && state.history.isEmpty && !state.isSleeping
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
                children: [
                  _SleepHero(state: state, goalHours: goal, controller: controller),
                  AppSpacing.gapMd,
                  SleepChartCard(nights: state.lastSevenNights, average: state.weeklyAverage, goalHours: goal),
                  AppSpacing.gapLg,
                  const SectionHeader(title: AppStrings.sleepHistory, compact: true),
                  AppSpacing.gapSm,
                  if (state.history.isEmpty)
                    SurfaceCard(child: Text(AppStrings.sleepHistoryEmpty, style: Theme.of(context).textTheme.bodyMedium))
                  else
                    for (final r in state.history) ...[
                      Dismissible(
                        key: ValueKey(r.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => confirmJournalDelete(context),
                        onDismissed: (_) => controller.deleteSleep(r.id),
                        background: const DeleteSwipeBackground(),
                        child: _SleepEntryCard(record: r, goalHours: goal),
                      ),
                      AppSpacing.gapSm,
                    ],
                ],
              ),
            ),
    );
  }
}

class _SleepHero extends StatelessWidget {
  final SleepState state;
  final int goalHours;
  final SleepController controller;

  const _SleepHero({required this.state, required this.goalHours, required this.controller});

  @override
  Widget build(BuildContext context) {
    final current = state.current;
    if (current != null) {
      return HealthHeroCard(
        title: '${AppStrings.sleepSleepingSince} ${clockTime(context, current.startTime)}',
        value: AppFormatters.duration(DateTime.now().difference(current.startTime)),
        valueSuffix: AppStrings.sleepSoFar,
        message: AppStrings.sleepGoodNight,
        actions: [
          HeroActionButton(icon: Icons.close_rounded, label: AppStrings.cancel, outlined: true, onPressed: controller.cancelSleep),
          HeroActionButton(icon: Icons.wb_sunny_rounded, label: AppStrings.sleepWakeUp, onPressed: controller.wakeUp),
        ],
      );
    }

    final last = state.last;
    final goal = Duration(hours: goalHours);
    final message = last == null
        ? AppStrings.sleepStartHint
        : last.duration! >= goal
            ? AppStrings.sleepGoalMet
            : '${AppFormatters.duration(goal - last.duration!)} ${AppStrings.sleepShortOfGoal}';

    return HealthHeroCard(
      title: AppStrings.sleepLastNight,
      value: last == null ? AppStrings.noData : AppFormatters.duration(last.duration!),
      message: message,
      actions: [
        HeroActionButton(icon: Icons.bedtime_rounded, label: AppStrings.sleepStart, onPressed: controller.startSleep),
      ],
    );
  }
}

class _SleepEntryCard extends StatelessWidget {
  final SleepRecord record;
  final int goalHours;

  const _SleepEntryCard({required this.record, required this.goalHours});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metGoal = record.duration! >= Duration(hours: goalHours);
    return SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppFormatters.weekdayDayMonth(record.endTime!), style: theme.textTheme.titleSmall),
                Text(
                  '${clockTime(context, record.startTime)} – ${clockTime(context, record.endTime!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(AppFormatters.duration(record.duration!), style: theme.textTheme.titleMedium),
          AppSpacing.hGapSm,
          Icon(
            metGoal ? Icons.check_circle_rounded : Icons.timelapse_rounded,
            color: metGoal ? sleepGoodColor : sleepShortColor,
            semanticLabel: metGoal ? AppStrings.sleepGoalMet : AppStrings.sleepBelowGoal,
          ),
        ],
      ),
    );
  }
}
