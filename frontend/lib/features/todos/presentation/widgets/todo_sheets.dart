import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/features/todos/presentation/controllers/todo_controller.dart';
import 'package:chronicle/features/todos/presentation/widgets/add_todo_sheet.dart';

/// Shared entry point for the Add Todo sheet, used by the Todos screen and
/// the global Quick Add button. [onSaved] runs after a successful save.
Future<void> showAddTodoSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => AddTodoSheet(
      onSubmit: (title, description, type) async {
        final ok = await ref.read(todoControllerProvider.notifier).addTodo(
              title: title,
              description: description,
              recurrenceType: type,
            );
        if (ok) onSaved?.call();
        return ok;
      },
    ),
  );
}
