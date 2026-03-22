import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';


import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/presentation/controllers/todo_controller.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_group_header.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_item_tile.dart';
import 'package:chronicle/features/todos/presentation/widgets/add_todo_sheet.dart';
import 'package:chronicle/features/todos/presentation/widgets/edit_todo_sheet.dart';
import 'package:chronicle/core/widgets/chronicle_button.dart';


class TodosScreen extends ConsumerWidget {
  const TodosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoControllerProvider);
    final theme = Theme.of(context);

    // Show error snackbar
    ref.listen(todoControllerProvider, (prev, next) {
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.todosLabel),
        actions: [
          if (!state.isLoading && state.totalCount > 0)
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: theme.colorScheme.onInverseSurface),
                  AppSpacing.hGapSm,
                  Text(
                    '${state.completedCount}/${state.totalCount}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.allTodos.isEmpty
              ? _EmptyState(onAdd: () => _showAddSheet(context, ref))
              : RefreshIndicator(
                  onRefresh: () => ref.read(todoControllerProvider.notifier).loadTodayTodos(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemCount: _calculateItemCount(state),
                    itemBuilder: (context, index) {
                      return _buildItem(context, ref, state, index);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Add Task'),
      ),
    );
  }

  int _calculateItemCount(TodoState state) {
    int count = 0;
    // Display order: daily → weekly → monthly → none
    for (final type in [RecurrenceType.daily, RecurrenceType.weekly, RecurrenceType.monthly, RecurrenceType.none]) {
      final items = state.groupedTodos[type];
      if (items != null && items.isNotEmpty) {
        count += 1 + items.length; // header + items
      }
    }
    return count;
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, TodoState state, int index) {
    int current = 0;
    for (final type in [RecurrenceType.daily, RecurrenceType.weekly, RecurrenceType.monthly, RecurrenceType.none]) {
      final items = state.groupedTodos[type];
      if (items == null || items.isEmpty) continue;

      if (index == current) {
        return TodoGroupHeader(type: type, count: items.length);
      }
      current++;

      if (index < current + items.length) {
        final instance = items[index - current];
        final template = state.templates.where((t) => t.id == instance.templateId).firstOrNull;

        return TodoItemTile(
          instance: instance,
          onToggle: () => ref
              .read(todoControllerProvider.notifier)
              .toggleComplete(instance.id, !instance.isCompleted),
          onEdit: () {
            if (template != null) {
              _showEditSheet(context, ref, template);
            }
          },
          onDelete: () {
            if (template != null) {
              _showDeleteDialog(context, ref, template);
            }
          },
        );
      }
      current += items.length;
    }
    return const SizedBox.shrink();
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddTodoSheet(
        onSubmit: (title, description, type) =>
            ref.read(todoControllerProvider.notifier).addTodo(
                  title: title,
                  description: description,
                  recurrenceType: type,
                ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, TodoTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => EditTodoSheet(
        currentTitle: template.title,
        currentDescription: template.description,
        currentType: template.recurrenceType,
        onSubmit: (title, description, type) =>
            ref.read(todoControllerProvider.notifier).editTodo(
                  templateId: template.id,
                  title: title,
                  description: description,
                  recurrenceType: type,
                ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, TodoTemplate template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${template.title}"? This will remove all instances of this todo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(todoControllerProvider.notifier).deleteTodo(template.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded, 
                size: 64, 
                color: theme.colorScheme.primary.withValues(alpha: 0.4)
              ),
            ),
            AppSpacing.gapLg,
            Text(
              AppStrings.noTodosYet, 
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapSm,
            Text(
              AppStrings.addFirstTodo, 
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,
            ChronicleButton(
              label: AppStrings.addTodo,
              onPressed: onAdd,
              size: ChronicleButtonSize.lg,
            ),
          ],
        ),
      ),
    );
  }
}
