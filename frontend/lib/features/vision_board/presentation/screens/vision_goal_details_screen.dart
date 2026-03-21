import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';
import 'package:chronicle/features/vision_board/presentation/widgets/add_goal_sheet.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';

class VisionGoalDetailsScreen extends ConsumerWidget {
  final VisionGoal goal;

  const VisionGoalDetailsScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = goal.status == 'completed';

    // Watch specifically for this goal's updates in the list if needed, 
    // but typically we pass the fresh goal or refresh on pop.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Strategy'),
        actions: [
          IconButton(
            icon: Icon(goal.isFavorite ? Icons.favorite : Icons.favorite_border, color: goal.isFavorite ? Colors.red : null),
            onPressed: () => ref.read(visionBoardControllerProvider.notifier).toggleFavorite(goal),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editGoal(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteGoal(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (goal.category != null)
              Chip(label: Text(goal.category!.toUpperCase())),
            AppSpacing.gapLg,
            Text(goal.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.gapMd,
            if (goal.description != null) ...[
              Text(goal.description!, style: theme.textTheme.bodyLarge),
              AppSpacing.gapLg,
            ],
            
            _DurationCard(goal: goal),
            AppSpacing.gapLg,

            Text('Current Progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.gapMd,
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: goal.progress / 100,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                AppSpacing.gapLg,
                Text('${goal.progress}%', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ],
            ),
            AppSpacing.gapXl,

            Text('The Master Plan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.gapMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                goal.plan ?? 'No strategic plan defined yet.',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
            
            if (isCompleted) ...[
              AppSpacing.gapXl,
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    AppSpacing.gapMd,
                    Text('Goal Achieved!', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddGoalSheet(goal: goal),
    );
  }

  Future<void> _deleteGoal(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(visionBoardControllerProvider.notifier).deleteGoal(goal.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _DurationCard extends StatelessWidget {
  final VisionGoal goal;
  const _DurationCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysRemaining = goal.targetDate?.difference(DateTime.now()).inDays ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
          AppSpacing.gapMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Timeline: ${goal.duration}', style: theme.textTheme.titleSmall),
              Text(
                goal.targetDate != null 
                  ? 'Target: ${DateFormat('MMMM yyyy').format(goal.targetDate!)} (${daysRemaining > 0 ? "$daysRemaining days left" : "Time is up!"})' 
                  : 'No deadline set',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
