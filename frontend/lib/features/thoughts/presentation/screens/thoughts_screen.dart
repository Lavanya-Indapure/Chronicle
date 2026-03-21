import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/thoughts/presentation/controllers/thought_controller.dart';
import 'package:chronicle/features/thoughts/presentation/widgets/add_thought_sheet.dart';
import 'package:chronicle/features/thoughts/domain/models/thought.dart';

class ThoughtsScreen extends ConsumerWidget {
  const ThoughtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(thoughtControllerProvider);
    final theme = Theme.of(context);
    final thoughts = state.filteredThoughts;
    final allTags = state.allTags;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thoughts & Quotes'),
        actions: [
          IconButton(
            icon: Icon(state.onlyFavorites ? Icons.favorite : Icons.favorite_border, color: state.onlyFavorites ? Colors.red : null),
            onPressed: () => ref.read(thoughtControllerProvider.notifier).toggleOnlyFavorites(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SearchBar(
              hintText: 'Search thoughts or tags...',
              leading: const Icon(Icons.search),
              onChanged: (value) => ref.read(thoughtControllerProvider.notifier).setSearchQuery(value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
            ),
          ),
          if (allTags.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                itemCount: allTags.length + 1,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterChip(
                      label: const Text('All'),
                      selected: state.selectedTag == null,
                      onSelected: (v) => ref.read(thoughtControllerProvider.notifier).setSelectedTag(null),
                    );
                  }
                  final tag = allTags[index - 1];
                  return FilterChip(
                    label: Text(tag),
                    selected: state.selectedTag == tag,
                    onSelected: (v) => ref.read(thoughtControllerProvider.notifier).setSelectedTag(v ? tag : null),
                  );
                },
              ),
            ),
          Expanded(
            child: state.isLoading && state.thoughts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : thoughts.isEmpty
                    ? _EmptyThoughts()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: thoughts.length,
                        itemBuilder: (context, index) {
                          final t = thoughts[index];
                          return _ThoughtCard(thought: t);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddThought(context),
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }

  void _showAddThought(BuildContext context, {Thought? thought}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddThoughtSheet(thought: thought),
    );
  }
}

class _ThoughtCard extends ConsumerWidget {
  final Thought thought;

  const _ThoughtCard({required this.thought});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tags = thought.tags?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _showEditThought(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, color: Colors.grey, size: 24),
                  AppSpacing.gapSm,
                  Expanded(
                    child: Text(
                      thought.content,
                      style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, height: 1.4),
                    ),
                  ),
                  IconButton(
                    icon: Icon(thought.isFavorite ? Icons.favorite : Icons.favorite_border, color: thought.isFavorite ? Colors.red : null),
                    onPressed: () => ref.read(thoughtControllerProvider.notifier).toggleFavorite(thought),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (tags.isNotEmpty) ...[
                AppSpacing.gapMd,
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('#$tag', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditThought(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddThoughtSheet(thought: thought),
    );
  }
}

class _EmptyThoughts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: theme.disabledColor),
          AppSpacing.gapMd,
          Text('No thoughts captured', style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)),
          AppSpacing.gapSm,
          const Text('Record your favorite quotes and ideas!'),
        ],
      ),
    );
  }
}
