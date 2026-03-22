import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/chronicle_card.dart';
import 'package:chronicle/core/widgets/chronicle_button.dart';
import 'package:chronicle/features/health/presentation/controllers/health_controllers.dart';
import 'package:chronicle/features/health/domain/models/health_models.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracking'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implementation for sleep settings or trends
            }, 
            icon: const Icon(Icons.show_chart_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SleepStatusCard(state: state, ref: ref),
          AppSpacing.gapLg,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'SLEEP HISTORY'.toUpperCase(), 
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          AppSpacing.gapMd,
          ...state.entries.map((e) => _SleepEntryTile(entry: e)),
          if (state.entries.isEmpty) ...[
            AppSpacing.gapXxl,
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded, 
                    size: 48, 
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  AppSpacing.gapMd,
                  Text(
                    'No sleep records yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final isSleeping = state.isSleeping;

    return ChronicleCard(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Icon(
              isSleeping ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded, 
              key: ValueKey(isSleeping),
              size: 72, 
              color: isSleeping ? Colors.indigo : Colors.orange,
            ),
          ),
          AppSpacing.gapLg,
          Text(
            isSleeping ? 'Good Night!' : 'Time for Rest?', 
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.gapSm,
          Text(
            isSleeping 
                ? 'Recording your sleep duration...' 
                : 'Track your sleep to improve wellness.', 
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapXl,
          ChronicleButton(
            onPressed: () => isSleeping 
                ? ref.read(sleepControllerProvider.notifier).wakeUp() 
                : ref.read(sleepControllerProvider.notifier).startSleep(),
            icon: isSleeping ? Icons.alarm_rounded : Icons.bedtime_rounded,
            label: isSleeping ? 'I AM AWAKE' : 'START SLEEP',
            size: ChronicleButtonSize.lg,
            color: isSleeping ? theme.colorScheme.secondary : theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _SleepEntryTile extends StatelessWidget {
  final SleepRecord entry;
  const _SleepEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = entry.duration?.inHours ?? 0;
    final m = (entry.duration?.inMinutes ?? 0) % 60;
    
    final isGoodSleep = h >= 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ChronicleCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.nightlight_round, color: Colors.indigo, size: 24),
          ),
          title: Text(
            '${h}h ${m}m sleep', 
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateFormat('EEEE, MMM dd').format(entry.startTime),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: (isGoodSleep ? Colors.green : Colors.orange).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGoodSleep ? Icons.sentiment_satisfied_alt_rounded : Icons.sentiment_neutral_rounded, 
              color: isGoodSleep ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
