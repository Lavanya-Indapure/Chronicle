import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/features/vision_board/domain/milestone_progress.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_milestone.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/milestones_controller.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';

/// Checklist of a goal's milestones: tap to tick, pencil to rename, swipe
/// to delete, drag the handle to reorder, type at the bottom to add.
class MilestonesSection extends ConsumerWidget {
  final VisionGoal goal;

  const MilestonesSection({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(milestonesProvider(goal.id));
    final controller = ref.read(milestonesProvider(goal.id).notifier);
    ref.listen(milestonesProvider(goal.id), (prev, next) {
      final message = next.errorMessage;
      if (message != null && message != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });
    final count = state.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppStrings.visionMilestonesTitle,
          subtitle: count.total == 0
              ? AppStrings.visionMilestonesSubtitle
              : '${count.done} ${AppStrings.visionMilestonesOf} ${count.total} ${AppStrings.visionMilestonesDone}',
          compact: true,
        ),
        AppSpacing.gapSm,
        if (state.unavailable)
          const _Notice()
        else if (state.isLoading && state.items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (MilestoneProgress.offerCompletion(items: state.items, status: goal.status)) ...[
            _CompletePrompt(onComplete: () => ref.read(visionBoardControllerProvider.notifier).markCompleted(goal)),
            AppSpacing.gapSm,
          ],
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                if (state.items.isNotEmpty)
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: controller.reorder,
                    children: [
                      for (var i = 0; i < state.items.length; i++)
                        Dismissible(
                          key: ValueKey(state.items[i].id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => confirmJournalDelete(context, title: AppStrings.visionMilestoneDeleteTitle),
                          onDismissed: (_) => controller.delete(state.items[i]),
                          background: const DeleteSwipeBackground(),
                          child: _MilestoneTile(
                            index: i,
                            milestone: state.items[i],
                            onToggle: () => controller.toggle(state.items[i]),
                            onRename: () => _rename(context, state.items[i], controller),
                          ),
                        ),
                    ],
                  ),
                _AddMilestoneField(onAdd: controller.add),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _rename(BuildContext context, VisionMilestone milestone, MilestonesController controller) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: milestone.title),
    );
    if (title != null) await controller.rename(milestone, title);
  }
}

class _MilestoneTile extends StatelessWidget {
  final int index;
  final VisionMilestone milestone;
  final VoidCallback onToggle;
  final VoidCallback onRename;

  const _MilestoneTile({required this.index, required this.milestone, required this.onToggle, required this.onRename});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final done = milestone.isDone;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Row(
            children: [
              Semantics(
                checked: done,
                label: milestone.title,
                child: Icon(
                  done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: done ? AppColors.success : colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + AppSpacing.xs),
                  child: Text(
                    milestone.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: done ? colors.onSurfaceVariant : colors.onSurface,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: AppStrings.visionMilestoneRename,
                visualDensity: VisualDensity.compact,
                onPressed: onRename,
                icon: Icon(Icons.edit_outlined, size: AppSpacing.lg - AppSpacing.xs, color: colors.onSurfaceVariant),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: colors.onSurfaceVariant,
                    semanticLabel: AppStrings.visionMilestoneReorder,
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

/// Inline "Add a milestone" field; keeps focus after adding for quick entry.
class _AddMilestoneField extends StatefulWidget {
  final Future<bool> Function(String) onAdd;

  const _AddMilestoneField({required this.onAdd});

  @override
  State<_AddMilestoneField> createState() => _AddMilestoneFieldState();
}

class _AddMilestoneFieldState extends State<_AddMilestoneField> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _text.text;
    if (value.trim().isEmpty) return;
    _text.clear();
    widget.onAdd(value);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('milestone-add-field'),
              controller: _text,
              focusNode: _focus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: AppStrings.visionMilestoneAddHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                prefixIcon: Icon(Icons.add_rounded),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _text,
            builder: (context, _) => _text.text.trim().isEmpty
                ? const SizedBox.shrink()
                : TextButton(onPressed: _submit, child: const Text(AppStrings.visionMilestoneAdd)),
          ),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  final String initial;

  const _RenameDialog({required this.initial});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.visionMilestoneRename),
      content: TextField(
        controller: _text,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, _text.text), child: const Text(AppStrings.visionMilestoneSave)),
      ],
    );
  }
}

/// Shown when every milestone is ticked but the goal isn't marked achieved.
class _CompletePrompt extends StatelessWidget {
  final VoidCallback onComplete;

  const _CompletePrompt({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: AppSpacing.borderRadiusXl),
      child: Row(
        children: [
          Expanded(
            child: Text(AppStrings.visionMilestonesAllDone, style: theme.textTheme.bodyMedium?.copyWith(color: ink)),
          ),
          AppSpacing.hGapSm,
          FilledButton(
            onPressed: onComplete,
            style: FilledButton.styleFrom(backgroundColor: ink, foregroundColor: theme.colorScheme.primaryContainer),
            child: const Text(AppStrings.visionMarkAchieved),
          ),
        ],
      ),
    );
  }
}

/// Migration not run yet.
class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.onSurfaceVariant),
          AppSpacing.hGapMd,
          Expanded(child: Text(AppStrings.visionMilestonesUnavailable, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
