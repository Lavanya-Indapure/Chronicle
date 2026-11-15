import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/presentation/controllers/todo_controller.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_group_header.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_item_tile.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_sheets.dart';
import 'package:chronicle/features/todos/presentation/widgets/edit_todo_sheet.dart';

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
          if (!state.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  '${state.completedCount}/${state.totalCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                    padding: AppSpacing.paddingScreen,
                    itemCount: _calculateItemCount(state),
                    itemBuilder: (context, index) {
                      return _buildItem(context, ref, state, index);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add),
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
    showAddTodoSheet(context, ref);
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          AppSpacing.gapMd,
          Text(AppStrings.noTodosYet, style: theme.textTheme.titleMedium),
          AppSpacing.gapSm,
          Text(AppStrings.addFirstTodo, style: theme.textTheme.bodySmall),
          AppSpacing.gapLg,
          FilledButton.tonal(
            onPressed: onAdd,
            child: const Text(AppStrings.addTodo),
          ),
        ],
      ),
    );
  }
}
