import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/health/presentation/widgets/health_widgets.dart';

class HealthSettingsScreen extends ConsumerWidget {
  const HealthSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthSettingsProvider);
    final controller = ref.read(healthSettingsProvider.notifier);
    ref.listen(healthSettingsProvider, (prev, next) => showHealthError(context, prev?.errorMessage, next.errorMessage));
    final s = state.settings;
    final theme = Theme.of(context);

    Future<void> pickTime(TimeOfDay initial, HealthSettings Function(TimeOfDay) apply) async {
      final picked = await showTimePicker(context: context, initialTime: initial);
      if (picked != null) await controller.update(apply(picked));
    }

    final slotCount = s.hydrationSlotTimes.length;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.healthSettingsTitle)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
              children: [
                const SectionHeader(title: AppStrings.hydration, compact: true),
                AppSpacing.gapSm,
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(AppStrings.healthRemindersToggle),
                        subtitle: const Text(AppStrings.healthRemindersHint),
                        value: s.notificationsEnabled,
                        onChanged: (v) => controller.update(s.copyWith(notificationsEnabled: v)),
                      ),
                      ListTile(
                        title: const Text(AppStrings.healthDayStart),
                        trailing: Text(s.hydrationStart.format(context), style: theme.textTheme.titleSmall),
                        onTap: () => pickTime(s.hydrationStart, (t) => s.copyWith(hydrationStart: t)),
                      ),
                      ListTile(
                        title: const Text(AppStrings.healthDayEnd),
                        trailing: Text(s.hydrationEnd.format(context), style: theme.textTheme.titleSmall),
                        onTap: () => pickTime(s.hydrationEnd, (t) => s.copyWith(hydrationEnd: t)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.healthInterval, style: theme.textTheme.bodyLarge),
                            AppSpacing.gapSm,
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final m in HealthSettings.intervalOptions)
                                  ChoiceChip(
                                    label: Text(_intervalLabel(m)),
                                    selected: s.hydrationIntervalMinutes == m,
                                    onSelected: (_) => controller.update(s.copyWith(hydrationIntervalMinutes: m)),
                                  ),
                              ],
                            ),
                            AppSpacing.gapSm,
                            Text(
                              slotCount == 0 ? AppStrings.healthNoSlotsWarning : '$slotCount ${AppStrings.healthGlassesPerDay}',
                              style: theme.textTheme.bodySmall?.copyWith(color: slotCount == 0 ? theme.colorScheme.error : null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapLg,
                const SectionHeader(title: AppStrings.sleep, compact: true),
                AppSpacing.gapSm,
                SurfaceCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(AppStrings.healthSleepGoal, style: theme.textTheme.bodyLarge)),
                      IconButton(
                        tooltip: AppStrings.healthLess,
                        onPressed: s.sleepGoalHours > HealthSettings.minSleepGoal
                            ? () => controller.update(s.copyWith(sleepGoalHours: s.sleepGoalHours - 1))
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Text('${s.sleepGoalHours}${AppStrings.sleepHoursShort}', style: theme.textTheme.titleMedium),
                      IconButton(
                        tooltip: AppStrings.healthMore,
                        onPressed: s.sleepGoalHours < HealthSettings.maxSleepGoal
                            ? () => controller.update(s.copyWith(sleepGoalHours: s.sleepGoalHours + 1))
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static String _intervalLabel(int minutes) =>
      minutes % 60 == 0 ? '${minutes ~/ 60}${AppStrings.sleepHoursShort}' : '$minutes${AppStrings.healthMinutesShort}';
}
