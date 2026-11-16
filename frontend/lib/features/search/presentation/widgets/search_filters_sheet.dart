import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/utils/formatters.dart';
import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/domain/search_module.dart';
import 'package:chronicle/features/search/presentation/controllers/search_controller.dart';
import 'package:chronicle/features/search/presentation/widgets/search_module_style.dart';

Future<void> showSearchFiltersSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SearchFiltersSheet(),
    );

/// "21 Oct – 3 Nov 2026"
String formatSearchRange(SearchDateRange r) =>
    '${AppFormatters.dayMonth(r.start)} – ${AppFormatters.dayMonthYear(r.end)}';

/// Picks a date range; returns null when cancelled.
Future<SearchDateRange?> pickSearchRange(BuildContext context, SearchDateRange? current) async {
  final now = DateTime.now();
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year, now.month, now.day),
    initialDateRange: current == null ? null : DateTimeRange(start: current.start, end: current.end),
  );
  return picked == null ? null : SearchDateRange(picked.start, picked.end);
}

/// Module, date, tag and expense-category filters. Changes apply live.
class SearchFiltersSheet extends ConsumerWidget {
  const SearchFiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final r = state.request;
    final theme = Theme.of(context);
    final showCategories =
        state.categories.isNotEmpty && r.tags.isEmpty && (r.modules.isEmpty || r.modules.contains(SearchModule.expenses));

    Widget title(String text) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
          child: Text(text, style: theme.textTheme.titleSmall),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(AppStrings.searchFilters, style: theme.textTheme.titleLarge)),
                if (r.hasFilters)
                  TextButton(onPressed: controller.clearFilters, child: const Text(AppStrings.searchClearFilters)),
              ],
            ),
            title(AppStrings.searchModules),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilterChip(
                  label: const Text(AppStrings.searchAllModules),
                  selected: r.modules.isEmpty,
                  onSelected: (_) => controller.clearModules(),
                ),
                for (final m in SearchModule.values)
                  FilterChip(
                    avatar: Icon(m.icon, size: AppSpacing.md, color: m.color),
                    label: Text(m.label),
                    selected: r.modules.contains(m),
                    onSelected: (_) => controller.toggleModule(m),
                  ),
              ],
            ),
            title(AppStrings.searchDates),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final range = await pickSearchRange(context, r.dateRange);
                      if (range != null) controller.setDateRange(range);
                    },
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(r.dateRange == null ? AppStrings.searchDates : formatSearchRange(r.dateRange!)),
                  ),
                ),
                if (r.dateRange != null)
                  IconButton(
                    tooltip: AppStrings.searchClearDates,
                    onPressed: () => controller.setDateRange(null),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            if (state.tagOptions.isNotEmpty) ...[
              title(AppStrings.searchTags),
              Text(AppStrings.searchTagsHint, style: theme.textTheme.bodySmall),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final tag in state.tagOptions)
                    FilterChip(
                      label: Text('#$tag'),
                      selected: r.tags.contains(tag),
                      onSelected: (_) => controller.toggleTag(tag),
                    ),
                ],
              ),
            ],
            if (showCategories) ...[
              title(AppStrings.searchCategory),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: const Text(AppStrings.searchAnyCategory),
                    selected: r.categoryId == null,
                    onSelected: (_) => controller.setCategory(null),
                  ),
                  for (final c in state.categories)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: r.categoryId == c.id,
                      onSelected: (v) => controller.setCategory(v ? c.id : null),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
