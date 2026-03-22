import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';

class HydrationScreen extends ConsumerWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydration'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implementation for manual log or history
            }, 
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          AppSpacing.gapLg,
          _HydrationCircularProgress(percentage: state.hydrationPercentage),
          AppSpacing.gapXl,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'TODAY\'S LOG'.toUpperCase(), 
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.doneReminders} / ${state.reminders.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.reminders.length,
              itemBuilder: (context, index) {
                final r = state.reminders[index];
                return _HydrationReminderTile(reminder: r, index: index, ref: ref);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationCircularProgress extends StatelessWidget {
  final double percentage;
  const _HydrationCircularProgress({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow/shadow ring
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 16,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              color: primaryColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toInt()}%', 
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900, 
                  color: primaryColor,
                ),
              ),
              Text(
                'of daily goal', 
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HydrationReminderTile extends StatelessWidget {
  final HydrationReminder reminder;
  final int index;
  final WidgetRef ref;
  const _HydrationReminderTile({required this.reminder, required this.index, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTime = '${reminder.logTime.hour.toString().padLeft(2, '0')}:00';
    
    Color statusColor;
    IconData statusIcon;
    
    switch (reminder.status) {
      case 'DONE':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'SKIPPED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'PENDING':
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.water_drop_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ChronicleCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          title: Text(
            'Water Intake', 
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            displayTime,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: reminder.status == 'PENDING' ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => ref.read(hydrationControllerProvider.notifier).markAsDone(reminder), 
                icon: const Icon(Icons.done_rounded, color: Colors.green),
                tooltip: 'Mark as done',
              ),
              IconButton(
                onPressed: () => ref.read(hydrationControllerProvider.notifier).markAsSkipped(reminder), 
                icon: const Icon(Icons.close_rounded, color: Colors.red),
                tooltip: 'Skip',
              ),
            ],
          ) : _StatusChip(status: reminder.status, color: statusColor),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
