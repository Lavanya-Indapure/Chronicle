import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/first_times/presentation/controllers/first_time_controller.dart';
import 'package:chronicle/features/first_times/domain/models/first_time_experience.dart';

class FirstTimeExperiencesScreen extends ConsumerWidget {
  const FirstTimeExperiencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(firstTimeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('First-Time Milestones')),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : state.experiences.isEmpty 
          ? _EmptyFirstTimes()
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.experiences.length,
              itemBuilder: (context, index) {
                final exp = state.experiences[index];
                return _FirstTimeTile(exp: exp);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExperience(context, ref),
        child: const Icon(Icons.star),
      ),
    );
  }

  void _showAddExperience(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddFirstTimeSheet(ref: ref),
    );
  }
}

class _FirstTimeTile extends StatelessWidget {
  final FirstTimeExperience exp;
  const _FirstTimeTile({required this.exp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.auto_awesome, size: 20)),
            title: Text(exp.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('MMMM dd, yyyy').format(exp.logDate)),
            trailing: exp.rating != null ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(' ${exp.rating}', style: theme.textTheme.labelLarge),
              ],
            ) : null,
          ),
          if (exp.description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Text(exp.description!, style: theme.textTheme.bodyMedium),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (exp.emotion != null)
                  Chip(
                    label: Text(exp.emotion!),
                    avatar: const Icon(Icons.mood, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                if (exp.location != null)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: theme.disabledColor),
                      Text(' ${exp.location}', style: theme.textTheme.labelSmall?.copyWith(color: theme.disabledColor)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFirstTimeSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddFirstTimeSheet({required this.ref});
  @override State<_AddFirstTimeSheet> createState() => _AddFirstTimeSheetState();
}

class _AddFirstTimeSheetState extends State<_AddFirstTimeSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locController = TextEditingController();
  String? _emotion = 'excited';
  final int _rating = 5;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Log First Experience', style: theme.textTheme.headlineSmall),
          AppSpacing.gapMd,
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Experience Title')),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'What happened?'), maxLines: 2),
          TextField(controller: _locController, decoration: const InputDecoration(labelText: 'Location')),
          AppSpacing.gapMd,
          ListTile(
            title: const Text('Date'),
            trailing: Text(DateFormat('yyyy-MM-dd').format(_date)),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1900), lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
          ),
          AppSpacing.gapMd,
          DropdownButtonFormField<String>(
            initialValue: _emotion,
            items: ['happy', 'nervous', 'excited', 'amazed', 'scared'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _emotion = v),
            decoration: const InputDecoration(labelText: 'How did you feel?'),
          ),
          AppSpacing.gapLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  widget.ref.read(firstTimeControllerProvider.notifier).createExperience(FirstTimeExperience(
                    id: '',
                    userId: '',
                    title: _titleController.text,
                    description: _descController.text,
                    logDate: _date,
                    emotion: _emotion,
                    rating: _rating,
                    location: _locController.text,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('LOG EXPERIENCE'),
            ),
          ),
          AppSpacing.gapXl,
        ],
      ),
    );
  }
}

class _EmptyFirstTimes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 64, color: theme.disabledColor),
          AppSpacing.gapMd,
          Text('Every first is special.', style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor)),
          Text('Record your life milestones here.', style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor)),
        ],
      ),
    );
  }
}
