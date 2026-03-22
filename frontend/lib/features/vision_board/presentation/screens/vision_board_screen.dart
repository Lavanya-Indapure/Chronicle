import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';
import 'package:chronicle/features/vision_board/presentation/widgets/add_goal_sheet.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';

class VisionBoardScreen extends ConsumerWidget {
  const VisionBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionBoardControllerProvider);
    final theme = Theme.of(context);
    final goals = state.filteredGoals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vision Board'),
        actions: [
          IconButton(
            icon: Icon(state.onlyFavorites ? Icons.favorite : Icons.favorite_border, color: state.onlyFavorites ? Colors.red : null),
            onPressed: () => ref.read(visionBoardControllerProvider.notifier).toggleOnlyFavorites(),
          ),
          PopupMenuButton<VisionSort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) => ref.read(visionBoardControllerProvider.notifier).setSortBy(sort),
            itemBuilder: (context) => [
              const PopupMenuItem(value: VisionSort.recency, child: Text('Recently Updated')),
              const PopupMenuItem(value: VisionSort.deadline, child: Text('Closest Deadline')),
              const PopupMenuItem(value: VisionSort.progress, child: Text('Highest Progress')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SearchBar(
              hintText: 'Search goals or categories...',
              leading: const Icon(Icons.search),
              onChanged: (value) => ref.read(visionBoardControllerProvider.notifier).setSearchQuery(value),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
            ),
          ),
          _FiltersRow(),
          Expanded(
            child: state.isLoading && state.goals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : goals.isEmpty
                    ? _EmptyVision()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: goals.length,
                        itemBuilder: (context, index) {
                          final g = goals[index];
                          return _GoalCard(goal: g);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoal(context),
        label: const Text('New Goal'),
        icon: const Icon(Icons.track_changes),
      ),
    );
  }

  void _showAddGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const AddGoalSheet(),
    );
  }
}

class _FiltersRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionBoardControllerProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Status'),
            selected: state.statusFilter == null,
            onSelected: (_) => ref.read(visionBoardControllerProvider.notifier).setStatusFilter(null),
          ),
          AppSpacing.gapSm,
          FilterChip(
            label: const Text('In Progress'),
            selected: state.statusFilter == 'inProgress',
            onSelected: (_) => ref.read(visionBoardControllerProvider.notifier).setStatusFilter('inProgress'),
          ),
          AppSpacing.gapSm,
          FilterChip(
            label: const Text('Completed'),
            selected: state.statusFilter == 'completed',
            onSelected: (_) => ref.read(visionBoardControllerProvider.notifier).setStatusFilter('completed'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final VisionGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = goal.status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: isCompleted ? Colors.green.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push('/more/vision-board/details', extra: goal),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (goal.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(goal.category!.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  const Spacer(),
                  if (goal.isFavorite) const Icon(Icons.favorite, color: Colors.red, size: 16),
                ],
              ),
              AppSpacing.gapSm,
              Text(goal.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (goal.description != null) ...[
                AppSpacing.gapXs,
                Text(goal.description!, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              AppSpacing.gapMd,
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: goal.progress / 100,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ),
                  AppSpacing.gapMd,
                  Text('${goal.progress}%', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              AppSpacing.gapMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: theme.disabledColor),
                      AppSpacing.gapXs,
                      Text(
                        goal.targetDate != null ? DateFormat('MMM yyyy').format(goal.targetDate!) : 'No deadline',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
                      ),
                    ],
                  ),
                  _StatusLabel(status: goal.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final String status;
  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'completed': color = Colors.green; label = 'COMPLETED'; break;
      case 'inProgress': color = Colors.orange; label = 'IN PROGRESS'; break;
      default: color = Colors.grey; label = 'NOT STARTED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _EmptyVision extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_mosaic_outlined, size: 64, color: theme.disabledColor),
          AppSpacing.gapMd,
          Text('Your Vision Board is empty', style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)),
          AppSpacing.gapSm,
          const Text('Define your goals and manifest your future!'),
        ],
      ),
    );
  }
}
