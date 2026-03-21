import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';

class HydrationScreen extends ConsumerWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hydration')),
      body: Column(
        children: [
          AppSpacing.gapLg,
          _HydrationCircularProgress(percentage: state.hydrationPercentage),
          AppSpacing.gapLg,
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 15,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            children: [
              Text('${percentage.toInt()}%', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              Text('of daily goal', style: theme.textTheme.bodySmall),
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
    final displayTime = '${reminder.logTime.hour.toString().padLeft(2, '0')}:00';

    return Card(
      child: ListTile(
        leading: Icon(
          reminder.status == 'DONE' ? Icons.check_circle : reminder.status == 'SKIPPED' ? Icons.cancel : Icons.water_drop,
          color: reminder.status == 'DONE' ? Colors.green : reminder.status == 'SKIPPED' ? Colors.red : Colors.blue,
        ),
        title: Text('Water Intake - $displayTime'),
        subtitle: Text('Status: ${reminder.status}'),
        trailing: reminder.status == 'PENDING' ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: () => ref.read(hydrationControllerProvider.notifier).markAsDone(reminder), icon: const Icon(Icons.done, color: Colors.green)),
            IconButton(onPressed: () => ref.read(hydrationControllerProvider.notifier).markAsSkipped(reminder), icon: const Icon(Icons.close, color: Colors.red)),
          ],
        ) : null,
      ),
    );
  }
}
