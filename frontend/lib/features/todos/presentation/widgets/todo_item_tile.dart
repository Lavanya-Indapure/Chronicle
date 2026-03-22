import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';

/// A single todo item tile with checkbox, title, badges, and actions.
import 'package:chronicle/core/widgets/chronicle_card.dart';

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
            title: const Text('Delete Task'),
            content: Text('Delete "${instance.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
      ),
      child: ChronicleCard(
        onTap: onEdit,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            // Custom-styled Checkbox/Toggle
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: (completed ? theme.colorScheme.outline : theme.colorScheme.onSurface).withValues(alpha: completed ? 0.6 : 1.0),
                size: 26,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
            AppSpacing.hGapMd,

            // Title + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instance.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: completed ? TextDecoration.lineThrough : null,
                      decorationColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      color: theme.colorScheme.onSurface.withValues(alpha: completed ? 0.6 : 1.0),
                      fontWeight: completed ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  if (instance.isCarriedForward) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.history_rounded, size: 12, color: Colors.amber.shade800),
                        const SizedBox(width: 4),
                        Text(
                          'Carried from yesterday',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Edit icon
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}
