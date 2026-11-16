import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/percent_ring.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/health/presentation/widgets/health_widgets.dart';

class HydrationScreen extends ConsumerWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationControllerProvider);
    final controller = ref.read(hydrationControllerProvider.notifier);
    ref.listen(hydrationControllerProvider, (prev, next) => showHealthError(context, prev?.errorMessage, next.errorMessage));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.hydration)),
      body: state.isLoading && state.slots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
                children: [
                  _HydrationHero(state: state, onLogGlass: controller.logGlass),
                  AppSpacing.gapLg,
                  const SectionHeader(
                    title: AppStrings.hydrationSchedule,
                    subtitle: AppStrings.hydrationScheduleHint,
                    compact: true,
                  ),
                  AppSpacing.gapSm,
                  if (state.slots.isEmpty)
                    SurfaceCard(child: Text(AppStrings.hydrationNoSlots, style: Theme.of(context).textTheme.bodyMedium))
                  else
                    _SlotGrid(
                      slots: state.slots,
                      onTap: (s) => s.status == HydrationStatus.pending ? controller.markDone(s) : controller.undo(s),
                      onLongPress: (s) => s.status == HydrationStatus.pending ? controller.markSkipped(s) : null,
                    ),
                ],
              ),
            ),
    );
  }
}

class _HydrationHero extends StatelessWidget {
  final HydrationState state;
  final VoidCallback onLogGlass;

  const _HydrationHero({required this.state, required this.onLogGlass});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;
    final next = state.nextUpcoming;
    final total = state.slots.length;

    final message = total > 0 && state.doneCount == total
        ? AppStrings.hydrationGoalReached
        : next == null
            ? AppStrings.hydrationKeepGoing
            : '${AppStrings.hydrationNextAt} ${clockTime(context, next.logTime)}';

    return HealthHeroCard(
      title: AppStrings.hydrationToday,
      value: '${state.doneCount}',
      valueSuffix: '${AppStrings.doneOf} $total ${AppStrings.hydrationGlasses}',
      message: message,
      trailing: PercentRing(
        fraction: state.fraction,
        color: ink,
        size: AppSpacing.ringSizeLg,
        strokeWidth: AppSpacing.ringStrokeLg,
        trackColor: ink.withValues(alpha: 0.12),
        labelStyle: theme.textTheme.titleSmall?.copyWith(color: ink),
      ),
      actions: [
        HeroActionButton(
          icon: Icons.water_drop_rounded,
          label: AppStrings.hydrationLogGlass,
          onPressed: state.nextToLog == null ? null : onLogGlass,
        ),
      ],
    );
  }
}

/// Four-per-row grid of slot chips.
class _SlotGrid extends StatelessWidget {
  static const _columns = 4;

  final List<HydrationReminder> slots;
  final ValueChanged<HydrationReminder> onTap;
  final ValueChanged<HydrationReminder> onLongPress;

  const _SlotGrid({required this.slots, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.sm * (_columns - 1)) / _columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in slots)
              SizedBox(
                width: width,
                child: _SlotChip(slot: s, onTap: () => onTap(s), onLongPress: () => onLongPress(s)),
              ),
          ],
        );
      },
    );
  }
}

class _SlotChip extends StatelessWidget {
  final HydrationReminder slot;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SlotChip({required this.slot, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final upcoming = slot.status == HydrationStatus.pending && slot.logTime.isAfter(DateTime.now());

    final (IconData icon, Color fg, Color bg, String status) = switch (slot.status) {
      HydrationStatus.done => (Icons.check_rounded, AppColors.info, AppColors.info.withValues(alpha: 0.14), AppStrings.hydrationDone),
      HydrationStatus.skipped => (Icons.close_rounded, colors.onSurfaceVariant, colors.surfaceContainerHighest, AppStrings.hydrationSkipped),
      HydrationStatus.pending => (
          Icons.water_drop_outlined,
          upcoming ? colors.onSurfaceVariant : AppColors.info,
          colors.surface,
          AppStrings.hydrationPending,
        ),
    };
    final time = clockTime(context, slot.logTime);

    return Semantics(
      button: true,
      label: '$time, $status',
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: AppSpacing.borderRadiusLg,
        child: InkWell(
          borderRadius: AppSpacing.borderRadiusLg,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + AppSpacing.xs),
            child: Column(
              children: [
                Icon(icon, color: fg, size: AppSpacing.lg - AppSpacing.xs),
                AppSpacing.gapXs,
                FittedBox(
                  child: Text(
                    time,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: upcoming ? colors.onSurfaceVariant : colors.onSurface,
                      decoration: slot.status == HydrationStatus.skipped ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
