import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Tracking')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SleepStatusCard(state: state, ref: ref),
          AppSpacing.gapLg,
          Text('Sleep History', style: theme.textTheme.titleMedium),
          AppSpacing.gapMd,
          ...state.entries.map((e) => _SleepEntryTile(entry: e)),
        ],
      ),
    );
  }
}

class _SleepStatusCard extends StatelessWidget {
  final SleepState state;
  final WidgetRef ref;
  const _SleepStatusCard({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(state.isSleeping ? Icons.nights_stay : Icons.wb_sunny_outlined, size: 64, color: theme.colorScheme.primary),
            AppSpacing.gapMd,
            Text(state.isSleeping ? 'Good Night!' : 'Time for Rest?', style: theme.textTheme.headlineSmall),
            AppSpacing.gapSm,
            Text(state.isSleeping ? 'Recording your sleep duration...' : 'Track your sleep to improve wellness.', textAlign: TextAlign.center),
            AppSpacing.gapLg,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => state.isSleeping ? ref.read(sleepControllerProvider.notifier).wakeUp() : ref.read(sleepControllerProvider.notifier).startSleep(),
                icon: Icon(state.isSleeping ? Icons.alarm : Icons.bedtime),
                label: Text(state.isSleeping ? 'I AM AWAKE' : 'START SLEEP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepEntryTile extends StatelessWidget {
  final SleepRecord entry;
  const _SleepEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final h = entry.duration?.inHours ?? 0;
    final m = (entry.duration?.inMinutes ?? 0) % 60;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.circle, size: 12, color: Colors.indigo),
        title: Text('${h}h ${m}m duration'),
        subtitle: Text(DateFormat('EEEE, MMM dd').format(entry.startTime)),
        trailing: Icon(h >= 7 ? Icons.sentiment_satisfied : Icons.sentiment_neutral, color: h >= 7 ? Colors.green : Colors.orange),
      ),
    );
  }
}
