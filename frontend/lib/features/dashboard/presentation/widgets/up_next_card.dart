import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/presentation/controllers/todo_controller.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_group_header.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_item_tile.dart';

/// Today's next few pending todos, tickable right from the dashboard.
class UpNextCard extends ConsumerWidget {
  const UpNextCard({super.key});

  static const _maxItems = 3;
  static const _groupOrder = [
    RecurrenceType.daily,
    RecurrenceType.weekly,
    RecurrenceType.monthly,
    RecurrenceType.none,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoControllerProvider);
    final theme = Theme.of(context);

    // Pending todos in display order, paired with their group's accent colour.
    final pending = <(TodoInstance, Color)>[
      for (final type in _groupOrder)
        for (final todo in state.groupedTodos[type] ?? const <TodoInstance>[])
          if (!todo.isCompleted) (todo, type.accent),
    ];
    final shown = pending.take(_maxItems).toList();
    final remaining = pending.length - shown.length;

    Future<void> complete(TodoInstance todo) async {
      await ref.read(todoControllerProvider.notifier).toggleComplete(todo.id, true);
      ref.read(dashboardControllerProvider.notifier).refresh();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppStrings.upNext,
          compact: true,
          trailing: TextButton(onPressed: () => context.go('/todos'), child: const Text(AppStrings.seeAll)),
        ),
        AppSpacing.gapXs,
        if (state.isLoading && state.allTodos.isEmpty)
          const SurfaceCard(child: Center(child: CircularProgressIndicator()))
        else if (shown.isEmpty)
          SurfaceCard(
            child: Text(
              state.totalCount == 0 ? AppStrings.noTodosToday : AppStrings.allCaughtUp,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          )
        else
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final (todo, accent) in shown)
                  _UpNextRow(key: ValueKey(todo.id), todo: todo, accent: accent, onComplete: () => complete(todo)),
                if (remaining > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
                    child: Text(
                      '${AppStrings.moreTodosPrefix}$remaining ${AppStrings.moreTodosSuffix}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UpNextRow extends StatelessWidget {
  final TodoInstance todo;
  final Color accent;
  final VoidCallback onComplete;

  const _UpNextRow({super.key, required this.todo, required this.accent, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          TodoCheckCircle(checked: false, accent: accent, onTap: onComplete, label: todo.title),
          AppSpacing.hGapXs,
          Expanded(
            child: Text(todo.title, style: theme.textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
