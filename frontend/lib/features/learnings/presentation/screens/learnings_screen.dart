import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/learnings/presentation/controllers/learning_controller.dart';
import 'package:chronicle/features/learnings/domain/models/learning.dart';

class LearningsScreen extends ConsumerWidget {
  const LearningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learningControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Learnings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search learnings...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (val) => ref.read(learningControllerProvider.notifier).setSearchQuery(val),
            ),
          ),
        ),
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : state.learnings.isEmpty 
          ? _EmptyLearnings()
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.filteredLearnings.length,
              itemBuilder: (context, index) {
                final learning = state.filteredLearnings[index];
                return _LearningCard(learning: learning);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLearning(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLearning(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddLearningSheet(ref: ref),
    );
  }
}

class _LearningCard extends StatelessWidget {
  final Learning learning;
  const _LearningCard({required this.learning});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (learning.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(learning.category!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                  ),
                const Spacer(),
                Text(DateFormat('MMM dd, yyyy').format(learning.logDate), style: theme.textTheme.labelSmall?.copyWith(color: theme.disabledColor)),
              ],
            ),
            AppSpacing.gapSm,
            Text(learning.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (learning.description != null) ...[
              AppSpacing.gapXs,
              Text(learning.description!, style: theme.textTheme.bodyMedium),
            ],
            if (learning.usefulnessRating != null) ...[
              AppSpacing.gapMd,
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    i < learning.usefulnessRating! ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  )),
                  const Spacer(),
                  if (learning.source != null)
                    Text('Source: ${learning.source}', style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddLearningSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddLearningSheet({required this.ref});
  @override State<_AddLearningSheet> createState() => _AddLearningSheetState();
}

class _AddLearningSheetState extends State<_AddLearningSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _sourceController = TextEditingController();
  String? _category = 'life';
  int _rating = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Learning', style: theme.textTheme.headlineSmall),
          AppSpacing.gapMd,
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'What did you learn?')),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Details (Optional)'), maxLines: 2),
          TextField(controller: _sourceController, decoration: const InputDecoration(labelText: 'Source (e.g., Book, Friend)')),
          AppSpacing.gapMd,
          DropdownButtonFormField<String>(
            value: _category,
            items: ['finance', 'technology', 'life', 'food', 'travel', 'other'].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _category = v),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          AppSpacing.gapMd,
          const Text('Usefulness Rating'),
          Slider(value: _rating.toDouble(), min: 1, max: 5, divisions: 4, label: _rating.toString(), onChanged: (v) => setState(() => _rating = v.toInt())),
          AppSpacing.gapLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  widget.ref.read(learningControllerProvider.notifier).addLearning(Learning(
                    id: '',
                    userId: '',
                    title: _titleController.text,
                    description: _descController.text,
                    category: _category,
                    source: _sourceController.text,
                    usefulnessRating: _rating,
                    logDate: DateTime.now(),
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('SAVE LEARNING'),
            ),
          ),
          AppSpacing.gapXl,
        ],
      ),
    );
  }
}

class _EmptyLearnings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: theme.disabledColor),
          AppSpacing.gapMd,
          Text('No learnings logged yet.', style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor)),
          Text('Tap the + button to record a new discovery!', style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor)),
        ],
      ),
    );
  }
}
