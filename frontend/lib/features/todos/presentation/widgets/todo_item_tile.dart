import 'package:flutter/material.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/features/todos/domain/models/todo_instance.dart';

/// One row inside a group card: check circle, title (+ note / carried-forward
/// tag). Tap the circle to complete, tap the row to edit, swipe left to delete.
class TodoItemTile extends StatelessWidget {
  final TodoInstance instance;
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoItemTile({
    super.key,
    required this.instance,
    required this.accent,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteTodoTitle),
        content: Text('${AppStrings.deleteTodoMessage} "${instance.title}"? ${AppStrings.deleteTodoAllInstances}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final completed = instance.isCompleted;
    final note = instance.description?.trim();

    return Dismissible(
      key: ValueKey(instance.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error,
        child: Icon(Icons.delete_outline_rounded, color: colors.onError),
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            children: [
              _CheckCircle(checked: completed, accent: accent, onTap: onToggle, label: instance.title),
              AppSpacing.hGapXs,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: completed ? colors.onSurfaceVariant : colors.onSurface,
                          decoration: completed ? TextDecoration.lineThrough : null,
                          decorationColor: colors.onSurfaceVariant,
                        ),
                        child: Text(instance.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      if (note != null && note.isNotEmpty)
                        Text(note, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (instance.isCarriedForward && !completed) ...[
                        AppSpacing.gapXs,
                        const _CarriedForwardTag(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round, animated check target (48dp hit area around a 26dp circle).
class _CheckCircle extends StatelessWidget {
  final bool checked;
  final Color accent;
  final VoidCallback onTap;
  final String label;

  const _CheckCircle({required this.checked, required this.accent, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      checked: checked,
      label: label,
      button: true,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: AppSpacing.lg,
        child: SizedBox.square(
          dimension: AppSpacing.iconButtonSize,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: AppSpacing.checkCircleSize,
              height: AppSpacing.checkCircleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? accent : Colors.transparent,
                border: Border.all(color: checked ? accent : colors.onSurfaceVariant, width: 2),
              ),
              child: AnimatedScale(
                scale: checked ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(Icons.check_rounded, size: AppSpacing.md, color: colors.surface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarriedForwardTag extends StatelessWidget {
  const _CarriedForwardTag();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs / 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.redo_rounded, size: AppSpacing.md - AppSpacing.xs, color: AppColors.warning),
          AppSpacing.hGapXs,
          Text(AppStrings.carriedForward, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.warning)),
        ],
      ),
    );
  }
}
