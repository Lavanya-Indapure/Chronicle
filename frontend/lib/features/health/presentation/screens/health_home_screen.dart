import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/circle_icon_button.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/health/presentation/screens/activity_screen.dart';
import 'package:chronicle/features/health/presentation/widgets/health_widgets.dart';

class HealthHomeScreen extends ConsumerWidget {
  const HealthHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydration = ref.watch(hydrationControllerProvider);
    final sleep = ref.watch(sleepControllerProvider);
    final activity = ref.watch(activityControllerProvider);
    final goal = ref.watch(healthSettingsProvider.select((s) => s.settings.sleepGoalHours));
    final theme = Theme.of(context);

    final today = activity.today;
    final activitiesDone = [today.exerciseDone, today.meditationDone].where((d) => d).length;
    final lastSleep = sleep.last;

    Future<void> refresh() => Future.wait([
          ref.read(healthSettingsProvider.notifier).load(),
          ref.read(hydrationControllerProvider.notifier).load(),
          ref.read(sleepControllerProvider.notifier).load(),
          ref.read(activityControllerProvider.notifier).load(),
        ]);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.healthLabel, style: theme.textTheme.headlineMedium),
                        Text(AppFormatters.weekdayDayMonth(DateTime.now()), style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.tune_rounded,
                    tooltip: AppStrings.healthSettingsTitle,
                    onPressed: () => context.push('/health/settings'),
                  ),
                ],
              ),
              AppSpacing.gapLg,
              HealthHeroCard(
                title: AppStrings.healthTodayTitle,
                value: '${hydration.doneCount}',
                valueSuffix: '${AppStrings.doneOf} ${hydration.slots.length} ${AppStrings.hydrationGlasses}',
                message: sleep.isSleeping
                    ? AppStrings.sleepGoodNight
                    : '${AppStrings.sleep}: ${lastSleep == null ? AppStrings.noData : AppFormatters.duration(lastSleep.duration!)}'
                        ' · ${AppStrings.activityTitle}: $activitiesDone/2',
              ),
              AppSpacing.gapLg,
              const SectionHeader(title: AppStrings.healthDailyTracking, compact: true),
              AppSpacing.gapSm,
              HealthFeatureCard(
                icon: Icons.water_drop_rounded,
                color: AppColors.info,
                title: AppStrings.hydration,
                value: AppFormatters.percent(hydration.fraction),
                caption: hydration.nextUpcoming == null
                    ? null
                    : '${AppStrings.hydrationNextAt} ${clockTime(context, hydration.nextUpcoming!.logTime)}',
                onTap: () => context.push('/health/hydration'),
              ),
              AppSpacing.gapSm,
              HealthFeatureCard(
                icon: Icons.bedtime_rounded,
                color: AppColors.chartBlue,
                title: AppStrings.sleep,
                value: sleep.isSleeping
                    ? '${AppStrings.sleepSleepingSince} ${clockTime(context, sleep.current!.startTime)}'
                    : lastSleep == null
                        ? AppStrings.noData
                        : '${AppStrings.sleepLastNight}: ${AppFormatters.duration(lastSleep.duration!)}',
                caption: sleep.weeklyAverage == null
                    ? '${AppStrings.sleepGoal} $goal${AppStrings.sleepHoursShort}'
                    : '${AppStrings.sleepWeekAvg} ${AppFormatters.duration(sleep.weeklyAverage!)} · '
                        '${AppStrings.sleepGoal} $goal${AppStrings.sleepHoursShort}',
                onTap: () => context.push('/health/sleep'),
              ),
              AppSpacing.gapSm,
              HealthFeatureCard(
                icon: Icons.fitness_center_rounded,
                color: exerciseColor,
                title: AppStrings.activityTitle,
                value: '$activitiesDone/2 ${AppStrings.activityDoneTodaySuffix}',
                caption: '${AppStrings.activityExercise} ${activity.exerciseStreak}${AppStrings.healthDaysShort} · '
                    '${AppStrings.activityMeditation} ${activity.meditationStreak}${AppStrings.healthDaysShort} '
                    '${AppStrings.activityStreakSuffix}',
                onTap: () => context.push('/health/activity'),
              ),
              AppSpacing.gapLg,
            ],
          ),
        ),
      ),
    );
  }
}
