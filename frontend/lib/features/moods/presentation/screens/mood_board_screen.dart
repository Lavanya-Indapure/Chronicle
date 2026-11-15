import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/learnings/presentation/widgets/journal_widgets.dart';
import 'package:chronicle/features/moods/domain/models/mood_entry.dart';
import 'package:chronicle/features/moods/presentation/controllers/mood_controller.dart';

/// Moods as stored in the database, with label and accent colour.
/// Emojis come from [MoodEntry.getEmoji] so they stay in one place.
enum MoodKind {
  happy('happy', AppStrings.moodHappy, AppColors.chartGreen),
  excited('excited', AppStrings.moodExcited, AppColors.chartLemon),
  neutral('neutral', AppStrings.moodNeutral, AppColors.chartBlue),
  tired('tired', AppStrings.moodTired, AppColors.chartOrchid),
  stressed('stressed', AppStrings.moodStressed, AppColors.chartOrange),
  sad('sad', AppStrings.moodSad, AppColors.chartCoral);

  final String key;
  final String label;
  final Color color;

  const MoodKind(this.key, this.label, this.color);

  String get emoji => MoodEntry.getEmoji(key);

  static MoodKind fromKey(String key) =>
      values.where((m) => m.key == key.toLowerCase()).firstOrNull ?? MoodKind.neutral;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class MoodBoardScreen extends ConsumerWidget {
  const MoodBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moodControllerProvider);
    final controller = ref.read(moodControllerProvider.notifier);
    final today = _day(DateTime.now());
    final todayEntry = state.moods.where((m) => _day(m.logDate) == today).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moodTitle)),
      body: state.isLoading && state.moods.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
              children: [
                _VibeCard(state: state),
                AppSpacing.gapMd,
                _RecentDaysStrip(moods: state.moods),
                AppSpacing.gapLg,
                SectionHeader(title: AppStrings.moodHowAreYou, compact: true),
                AppSpacing.gapSm,
                _MoodPicker(
                  todayMood: todayEntry == null ? null : MoodKind.fromKey(todayEntry.mood),
                  onLog: controller.logMood,
                ),
                AppSpacing.gapLg,
                SectionHeader(title: AppStrings.moodHistory, compact: true),
                AppSpacing.gapSm,
                if (state.moods.isEmpty)
                  SurfaceCard(
                    child: Center(
                      child: Text(AppStrings.moodHistoryEmpty, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else
                  ...groupByMonth<MoodEntry>(
                    items: state.moods,
                    dateOf: (m) => m.logDate,
                    header: (label) => Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    item: (m) => Dismissible(
                      key: ValueKey(m.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => confirmJournalDelete(context),
                      onDismissed: (_) => controller.deleteMood(m.id),
                      background: const DeleteSwipeBackground(),
                      child: _MoodEntryCard(mood: m),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Lemon card: most frequent mood overall.
class _VibeCard extends StatelessWidget {
  final MoodState state;

  const _VibeCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = colors.onPrimaryContainer;
    final count = state.moods.length;
    final vibe = MoodKind.fromKey(state.mostFrequentMood);

    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppSpacing.borderRadiusXl),
      child: Row(
        children: [
          Container(
            width: AppSpacing.xxxl,
            height: AppSpacing.xxxl,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: ink.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Text(count == 0 ? MoodKind.neutral.emoji : vibe.emoji, style: theme.textTheme.headlineLarge),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.moodOverallVibe, style: theme.textTheme.titleSmall?.copyWith(color: ink)),
                if (count == 0)
                  Text(AppStrings.moodNoEntries, style: theme.textTheme.bodyMedium?.copyWith(color: ink))
                else ...[
                  Text(vibe.label, style: theme.textTheme.headlineMedium?.copyWith(color: ink, fontWeight: FontWeight.w700)),
                  Text(
                    '${AppStrings.moodBasedOnPrefix} $count ${count == 1 ? AppStrings.moodEntrySuffix : AppStrings.moodEntriesSuffix}',
                    style: theme.textTheme.bodySmall?.copyWith(color: ink),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two rows of seven days (oldest → today) showing each day's mood emoji.
class _RecentDaysStrip extends StatelessWidget {
  final List<MoodEntry> moods;

  const _RecentDaysStrip({required this.moods});

  static const _days = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _day(DateTime.now());
    final byDay = {for (final m in moods) _day(m.logDate): MoodKind.fromKey(m.mood)};
    final days = [for (var i = _days - 1; i >= 0; i--) today.subtract(Duration(days: i))];

    Widget cell(DateTime d) {
      final mood = byDay[d];
      final isToday = d == today;
      return Expanded(
        child: Column(
          children: [
            Text(DateFormat('E').format(d).characters.first, style: theme.textTheme.labelSmall),
            AppSpacing.gapXs,
            Container(
              width: AppSpacing.xl + 4,
              height: AppSpacing.xl + 4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mood?.color.withValues(alpha: 0.2) ?? theme.colorScheme.surfaceContainerLowest,
                border: isToday ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
              ),
              child: mood == null
                  ? Text('${d.day}', style: theme.textTheme.labelSmall)
                  : Text(mood.emoji, style: theme.textTheme.titleMedium),
            ),
          ],
        ),
      );
    }

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.moodLast14Days, style: theme.textTheme.titleSmall),
          AppSpacing.gapMd,
          Row(children: [for (final d in days.take(7)) cell(d)]),
          AppSpacing.gapMd,
          Row(children: [for (final d in days.skip(7)) cell(d)]),
        ],
      ),
    );
  }
}

/// 3×2 grid of moods; picking one reveals a note field and Log button.
/// Logging again on the same day replaces that day's mood.
class _MoodPicker extends StatefulWidget {
  final MoodKind? todayMood;
  final Future<void> Function(String mood, String? note) onLog;

  const _MoodPicker({required this.todayMood, required this.onLog});

  @override
  State<_MoodPicker> createState() => _MoodPickerState();
}

class _MoodPickerState extends State<_MoodPicker> {
  final _noteController = TextEditingController();
  MoodKind? _selected;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _log() {
    final note = _noteController.text.trim();
    widget.onLog(_selected!.key, note.isEmpty ? null : note);
    _noteController.clear();
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = widget.todayMood;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (today != null) ...[
            Text(
              '${AppStrings.moodTodayPrefix} ${today.emoji} ${today.label} — ${AppStrings.moodTapToChange}',
              style: theme.textTheme.bodySmall,
            ),
            AppSpacing.gapMd,
          ],
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.25,
            children: [
              for (final m in MoodKind.values)
                _MoodTile(
                  mood: m,
                  selected: _selected == m,
                  isToday: _selected == null && today == m,
                  onTap: () => setState(() => _selected = _selected == m ? null : m),
                ),
            ],
          ),
          if (_selected != null) ...[
            AppSpacing.gapMd,
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: AppStrings.moodNoteHint),
            ),
            AppSpacing.gapMd,
            FilledButton(onPressed: _log, child: Text('${AppStrings.moodLog} · ${_selected!.emoji}')),
          ],
        ],
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  final MoodKind mood;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  const _MoodTile({required this.mood, required this.selected, required this.isToday, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlighted = selected || isToday;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: highlighted ? mood.color.withValues(alpha: 0.22) : theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: selected ? BorderSide(color: mood.color, width: 2) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mood.emoji, style: theme.textTheme.headlineSmall),
              AppSpacing.gapXs,
              Text(mood.label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodEntryCard extends StatelessWidget {
  final MoodEntry mood;

  const _MoodEntryCard({required this.mood});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = MoodKind.fromKey(mood.mood);
    final note = mood.note?.trim();

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconBadgeSize,
            height: AppSpacing.iconBadgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: kind.color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Text(kind.emoji, style: theme.textTheme.titleLarge),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kind.label, style: theme.textTheme.titleMedium),
                if (note != null && note.isNotEmpty)
                  Text(note, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          Text(AppFormatters.shortDate(mood.logDate), style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
