import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/moods/presentation/controllers/mood_controller.dart';
import 'package:chronicle/features/moods/domain/models/mood_entry.dart';

class MoodBoardScreen extends ConsumerWidget {
  const MoodBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moodControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Board')),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _MoodSummaryCard(state: state),
              AppSpacing.gapLg,
              Text('How are you today?', style: theme.textTheme.titleMedium),
              AppSpacing.gapMd,
              _MoodPicker(ref: ref),
              AppSpacing.gapLg,
              Text('Recent Reflections', style: theme.textTheme.titleMedium),
              AppSpacing.gapMd,
              ...state.moods.map((m) => _MoodEntryTile(mood: m)),
            ],
          ),
    );
  }
}

class _MoodSummaryCard extends StatelessWidget {
  final MoodState state;
  const _MoodSummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mostFreq = state.mostFrequentMood;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text('Overall Vibe', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            AppSpacing.gapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(MoodEntry.getEmoji(mostFreq), style: const TextStyle(fontSize: 48)),
                AppSpacing.gapMd,
                Text(mostFreq.toUpperCase(), style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodPicker extends StatefulWidget {
  final WidgetRef ref;
  const _MoodPicker({required this.ref});
  @override State<_MoodPicker> createState() => _MoodPickerState();
}

class _MoodPickerState extends State<_MoodPicker> {
  final _noteController = TextEditingController();
  String? _selected;

  final moods = [
    {'label': 'happy', 'emoji': '😊'},
    {'label': 'excited', 'emoji': '🤩'},
    {'label': 'neutral', 'emoji': '😐'},
    {'label': 'tired', 'emoji': '😴'},
    {'label': 'stressed', 'emoji': '😫'},
    {'label': 'sad', 'emoji': '😢'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          children: moods.map((m) => ChoiceChip(
            label: Text('${m['emoji']} ${m['label']}'),
            selected: _selected == m['label'],
            onSelected: (val) => setState(() => _selected = val ? m['label'] : null),
          )).toList(),
        ),
        if (_selected != null) ...[
          AppSpacing.gapMd,
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(hintText: 'Add a quick note (optional)...'),
          ),
          AppSpacing.gapMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.ref.read(moodControllerProvider.notifier).logMood(_selected!, _noteController.text);
                _noteController.clear();
                setState(() => _selected = null);
              },
              child: const Text('LOG MOOD'),
            ),
          ),
        ],
      ],
    );
  }
}

class _MoodEntryTile extends StatelessWidget {
  final MoodEntry mood;
  const _MoodEntryTile({required this.mood});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Text(MoodEntry.getEmoji(mood.mood), style: const TextStyle(fontSize: 24)),
        title: Text(mood.mood.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: mood.note != null ? Text(mood.note!) : null,
        trailing: Text(DateFormat('MMM dd').format(mood.logDate), style: theme.textTheme.labelSmall),
      ),
    );
  }
}
