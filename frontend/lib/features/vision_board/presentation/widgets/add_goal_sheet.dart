import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/widgets/draft_form_mixin.dart';
import 'package:chronicle/core/widgets/draft_restored_banner.dart';
import 'package:chronicle/features/vision_board/presentation/controllers/vision_board_controller.dart';
import 'package:chronicle/features/vision_board/domain/models/vision_goal.dart';

class AddGoalSheet extends ConsumerStatefulWidget {
  final VisionGoal? goal;

  const AddGoalSheet({super.key, this.goal});

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> with DraftFormMixin<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _planController = TextEditingController();
  
  String _duration = '6m';
  DateTime? _targetDate;
  int _progress = 0;
  String _status = 'not_started';
  bool _isFavorite = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> _durationOptions = [
    {'value': '1m', 'label': '1 Month'},
    {'value': '3m', 'label': '3 Months'},
    {'value': '6m', 'label': '6 Months'},
    {'value': '1y', 'label': '1 Year'},
    {'value': '3y', 'label': '3 Years'},
    {'value': '5y', 'label': '5 Years'},
  ];

  /// The form's starting values (new goal defaults or the goal being edited);
  /// draft keys that are missing fall back to these.
  Map<String, Object?> _startValues = const {};

  // ── Draft ──
  @override
  String get draftKey => widget.goal == null ? 'goal:new' : 'goal:edit:${widget.goal!.id}';

  @override
  Map<String, Object?> captureDraft() => {
        'title': _titleController.text,
        'description': _descController.text,
        'category': _categoryController.text,
        'plan': _planController.text,
        'duration': _duration,
        'targetDate': _targetDate,
        'progress': _progress,
        'status': _status,
        'isFavorite': _isFavorite,
      };

  @override
  void restoreDraft(Map<String, Object?> draft) {
    final v = {..._startValues, ...draft};
    _titleController.text = v['title'] as String? ?? '';
    _descController.text = v['description'] as String? ?? '';
    _categoryController.text = v['category'] as String? ?? '';
    _planController.text = v['plan'] as String? ?? '';
    _duration = v['duration'] as String? ?? '6m';
    _targetDate = v['targetDate'] as DateTime?;
    _progress = v['progress'] as int? ?? 0;
    _status = v['status'] as String? ?? 'not_started';
    _isFavorite = v['isFavorite'] as bool? ?? false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _descController.text = widget.goal!.description ?? '';
      _categoryController.text = widget.goal!.category ?? '';
      _planController.text = widget.goal!.plan ?? '';
      _duration = widget.goal!.duration;
      _targetDate = widget.goal!.targetDate;
      _progress = widget.goal!.progress;
      _status = widget.goal!.status;
      _isFavorite = widget.goal!.isFavorite;
    } else {
      _calculateTargetDate();
    }
    _startValues = captureDraft();
    initDraft();
  }

  void _calculateTargetDate() {
    final now = DateTime.now();
    DateTime date;
    switch (_duration) {
      case '1m': date = DateTime(now.year, now.month + 1, now.day); break;
      case '3m': date = DateTime(now.year, now.month + 3, now.day); break;
      case '6m': date = DateTime(now.year, now.month + 6, now.day); break;
      case '1y': date = DateTime(now.year + 1, now.month, now.day); break;
      case '3y': date = DateTime(now.year + 3, now.month, now.day); break;
      case '5y': date = DateTime(now.year + 5, now.month, now.day); break;
      default: date = DateTime(now.year, now.month + 6, now.day);
    }
    setState(() => _targetDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final goal = VisionGoal(
        id: widget.goal?.id ?? '',
        userId: widget.goal?.userId ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        duration: _duration,
        targetDate: _targetDate,
        plan: _planController.text.trim().isEmpty ? null : _planController.text.trim(),
        progress: _progress,
        status: _status,
        isFavorite: _isFavorite,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.goal == null) {
        await ref.read(visionBoardControllerProvider.notifier).createGoal(goal);
      } else {
        await ref.read(visionBoardControllerProvider.notifier).updateGoal(widget.goal!.id, goal);
      }
      // The controller reports failures via errorMessage (it doesn't throw);
      // on failure keep the sheet open so the input isn't lost.
      final failed = ref.read(visionBoardControllerProvider).errorMessage != null;
      if (failed) return;
      markSubmitted();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.goal == null ? 'Set New Goal' : 'Edit Manifestation', style: theme.textTheme.titleLarge),
              AppSpacing.gapLg,
              if (draftRestored) ...[
                DraftRestoredBanner(onDiscard: discardDraft),
                AppSpacing.gapMd,
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Goal Title', prefixIcon: Icon(Icons.stars_outlined)),
                validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (What does this look like?)'),
                maxLines: 2,
              ),
              AppSpacing.gapMd,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category', hintText: 'Personal, Career...'),
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, // ellipsize long labels instead of overflowing
                      value: _duration,
                      decoration: const InputDecoration(labelText: 'Timeline'),
                      items: _durationOptions.map((opt) => DropdownMenuItem(value: opt['value'], child: Text(opt['label']!))).toList(),
                      onChanged: (v) {
                        setState(() => _duration = v!);
                        _calculateTargetDate();
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _planController,
                decoration: const InputDecoration(
                  labelText: 'The Plan (How will you achieve this?)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              AppSpacing.gapLg,
              if (widget.goal != null) ...[
                Text('Progress (${_progress}%)', style: theme.textTheme.labelMedium),
                Slider(
                  value: _progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$_progress%',
                  onChanged: (v) => setState(() => _progress = v.toInt()),
                ),
                AppSpacing.gapSm,
                DropdownButtonFormField<String>(
                    isExpanded: true, // ellipsize long labels instead of overflowing
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'not_started', child: Text('⏳ Not Started')),
                    DropdownMenuItem(value: 'in_progress', child: Text('🚀 In Progress')),
                    DropdownMenuItem(value: 'completed', child: Text('✅ Completed')),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
                AppSpacing.gapMd,
              ],
              SwitchListTile.adaptive(
                title: const Text('Add to Favorites'),
                value: _isFavorite,
                onChanged: (v) => setState(() => _isFavorite = v),
                secondary: const Icon(Icons.favorite, color: Colors.red),
              ),
              AppSpacing.gapLg,
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting ? const CircularProgressIndicator() : Text(widget.goal == null ? 'Manifest Goal' : 'Update Manifestation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
