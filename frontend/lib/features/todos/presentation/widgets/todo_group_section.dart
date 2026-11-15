import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';
import 'package:chronicle/features/todos/domain/models/todo_template.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_group_header.dart';
import 'package:chronicle/features/todos/presentation/widgets/todo_item_tile.dart';

/// A recurrence group: header + one rounded card holding its rows,
/// with pending todos first and completed ones sunk to the bottom.
class TodoGroupSection extends StatelessWidget {
  final RecurrenceType type;
  final List<TodoInstance> items;
  final ValueChanged<TodoInstance> onToggle;
  final ValueChanged<TodoInstance> onEdit;
  final ValueChanged<TodoInstance> onDelete;

  const TodoGroupSection({
    super.key,
    required this.type,
    required this.items,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).colorScheme.outline;
    final sorted = [
      ...items.where((i) => !i.isCompleted),
      ...items.where((i) => i.isCompleted),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TodoGroupHeader(
          type: type,
          completed: items.where((i) => i.isCompleted).length,
          total: items.length,
        ),
        AppSpacing.gapSm,
        SurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < sorted.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: divider,
                    // Line up with the title, not the check circle.
                    indent: AppSpacing.sm + AppSpacing.iconButtonSize + AppSpacing.xs,
                    endIndent: AppSpacing.md,
                  ),
                TodoItemTile(
                  key: ValueKey(sorted[i].id),
                  instance: sorted[i],
                  accent: type.accent,
                  onToggle: () => onToggle(sorted[i]),
                  onEdit: () => onEdit(sorted[i]),
                  onDelete: () => onDelete(sorted[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
