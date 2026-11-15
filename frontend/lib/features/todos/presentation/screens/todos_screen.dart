import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/circle_icon_button.dart';
import 'package:chronicle/core/widgets/icon_badge.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/presentation/controllers/todo_controller.dart';
import 'package:chronicle/features/todos/presentation/widgets/edit_todo_sheet.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_group_section.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_progress_card.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_sheets.dart';

class TodosScreen extends ConsumerWidget {
  const TodosScreen({super.key});

  /// Display order of the recurrence groups.
  static const _groupOrder = [
    RecurrenceType.daily,
    RecurrenceType.weekly,
    RecurrenceType.monthly,
    RecurrenceType.none,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoControllerProvider);
    final controller = ref.read(todoControllerProvider.notifier);

    ref.listen(todoControllerProvider, (prev, next) {
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    TodoTemplate? templateOf(TodoInstance i) => state.templates.where((t) => t.id == i.templateId).firstOrNull;

    final groups = [
      for (final type in _groupOrder)
        if (state.groupedTodos[type]?.isNotEmpty ?? false) (type, state.groupedTodos[type]!),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => controller.loadTodayTodos(silent: true),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
            children: [
              _Header(onAdd: () => showAddTodoSheet(context, ref)),
              AppSpacing.gapLg,
              if (state.isLoading && state.allTodos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xxxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.allTodos.isEmpty)
                _EmptyState(onAdd: () => showAddTodoSheet(context, ref))
              else ...[
                TodoProgressCard(completed: state.completedCount, total: state.totalCount),
                for (final (type, items) in groups) ...[
                  AppSpacing.gapLg,
                  TodoGroupSection(
                    type: type,
                    items: items,
                    onToggle: (i) => controller.toggleComplete(i.id, !i.isCompleted),
                    onEdit: (i) {
                      final template = templateOf(i);
                      if (template != null) _showEditSheet(context, ref, template);
                    },
                    onDelete: (i) {
                      if (i.templateId != null) controller.deleteTodo(i.templateId!);
                    },
                  ),
                ],
                AppSpacing.gapLg,
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, TodoTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EditTodoSheet(
        currentTitle: template.title,
        currentDescription: template.description,
        currentType: template.recurrenceType,
        onSubmit: (title, description, type) => ref.read(todoControllerProvider.notifier).editTodo(
              templateId: template.id,
              title: title,
              description: description,
              recurrenceType: type,
            ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAdd;

  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.todosLabel, style: theme.textTheme.headlineMedium),
              Text(AppFormatters.weekdayDayMonth(DateTime.now()), style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        CircleIconButton(icon: Icons.add_rounded, tooltip: AppStrings.addTodo, onPressed: onAdd),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        children: [
          IconBadge(
            icon: Icons.check_rounded,
            color: theme.colorScheme.primaryContainer,
            onColor: theme.colorScheme.onPrimaryContainer,
            filled: true,
            size: AppSpacing.xxxl,
          ),
          AppSpacing.gapLg,
          Text(AppStrings.noTodosYet, style: theme.textTheme.titleLarge),
          AppSpacing.gapXs,
          Text(AppStrings.addFirstTodo, style: theme.textTheme.bodyMedium),
          AppSpacing.gapLg,
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text(AppStrings.addTodo),
          ),
        ],
      ),
    );
  }
}
