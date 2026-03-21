import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';

/// A single todo item tile with checkbox, title, badges, and actions.
class TodoItemTile extends StatelessWidget {
  final TodoInstance instance;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoItemTile({
    super.key,
    required this.instance,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = instance.isCompleted;

    return Dismissible(
      key: Key(instance.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.deleteTodoTitle),
            content: Text('${AppStrings.deleteTodoMessage} "${instance.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      child: Card(
        child: InkWell(
          onTap: onEdit,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: completed,
                  onChanged: (_) => onToggle(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AppSpacing.hGapSm,

                // Title + badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instance.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: completed ? TextDecoration.lineThrough : null,
                          color: completed
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                              : theme.colorScheme.onSurface,
                          fontWeight: completed ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                      if (instance.isCarriedForward) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.redo, size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.carriedForward,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Edit icon
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
