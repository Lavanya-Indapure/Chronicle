import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/core/theme/app_colors.dart';
import 'package:chronicle/core/widgets/app_search_field.dart';
import 'package:chronicle/core/widgets/empty_state.dart';
import 'package:chronicle/core/widgets/section_header.dart';
import 'package:chronicle/core/widgets/surface_card.dart';
import 'package:chronicle/features/search/domain/search_models.dart';
import 'package:chronicle/features/search/domain/search_query_builder.dart';
import 'package:chronicle/features/search/presentation/controllers/search_controller.dart';
import 'package:chronicle/features/search/presentation/widgets/search_filters_sheet.dart';
import 'package:chronicle/features/search/presentation/widgets/search_module_style.dart';
import 'package:chronicle/features/search/presentation/widgets/search_result_tile.dart';

/// Search across every module, with module / date / tag / category filters.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.searchTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.sm),
            child: AppSearchField(hint: AppStrings.searchEverythingHint, onChanged: controller.setQuery, autofocus: true),
          ),
          _FilterBar(state: state, controller: controller),
          if (state.status == SearchStatus.loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(child: _Body(state: state, onRetry: controller.search)),
        ],
      ),
    );
  }
}

/// "Filters (2)" button plus removable chips for each active filter.
class _FilterBar extends StatelessWidget {
  final SearchState state;
  final GlobalSearchController controller;

  const _FilterBar({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final r = state.request;
    final category = state.categories.where((c) => c.id == r.categoryId).firstOrNull;
    final count = r.filterCount;

    return SizedBox(
      height: AppSpacing.xxl,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.paddingGutter,
        children: [
          ActionChip(
            avatar: const Icon(Icons.tune_rounded, size: AppSpacing.md),
            label: Text(count == 0 ? AppStrings.searchFilters : '${AppStrings.searchFilters} ($count)'),
            onPressed: () => showSearchFiltersSheet(context),
          ),
          AppSpacing.hGapSm,
          ActionChip(
            avatar: const Icon(Icons.date_range_rounded, size: AppSpacing.md),
            label: Text(r.dateRange == null ? AppStrings.searchDates : formatSearchRange(r.dateRange!)),
            onPressed: () async {
              final range = await pickSearchRange(context, r.dateRange);
              if (range != null) controller.setDateRange(range);
            },
          ),
          if (r.dateRange != null) ...[
            AppSpacing.hGapXs,
            IconButton(
              tooltip: AppStrings.searchClearDates,
              visualDensity: VisualDensity.compact,
              onPressed: () => controller.setDateRange(null),
              icon: const Icon(Icons.close_rounded, size: AppSpacing.md + AppSpacing.xs),
            ),
          ],
          for (final m in r.modules) ...[
            AppSpacing.hGapSm,
            InputChip(label: Text(m.label), onDeleted: () => controller.toggleModule(m)),
          ],
          for (final t in r.tags) ...[
            AppSpacing.hGapSm,
            InputChip(label: Text('#$t'), onDeleted: () => controller.toggleTag(t)),
          ],
          if (category != null) ...[
            AppSpacing.hGapSm,
            InputChip(label: Text(category.name), onDeleted: () => controller.setCategory(null)),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final SearchState state;
  final VoidCallback onRetry;

  const _Body({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final query = state.request.trimmedQuery;

    if (state.status == SearchStatus.idle) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: AppStrings.searchStartTitle,
        message: AppStrings.searchStartMessage,
        muted: true,
      );
    }
    if (state.status == SearchStatus.loading && state.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == SearchStatus.error) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: AppStrings.searchErrorTitle,
        message: state.errorMessage ?? AppStrings.unknownError,
        actionLabel: AppStrings.searchRetry,
        onAction: onRetry,
      );
    }

    final groups = state.withItems;
    final failed = state.failedModules;
    if (groups.isEmpty) {
      return Column(
        children: [
          if (failed.isNotEmpty) _PartialFailureNotice(modules: failed.map((m) => m.label).toList()),
          const Expanded(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: AppStrings.searchNoMatchesTitle,
              message: AppStrings.searchNoMatchesMessage,
              muted: true,
            ),
          ),
        ],
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
      children: [
        if (failed.isNotEmpty) ...[
          _PartialFailureNotice(modules: failed.map((m) => m.label).toList(), padded: false),
          AppSpacing.gapMd,
        ],
        for (final group in groups) ...[
          _GroupHeader(group: group),
          AppSpacing.gapSm,
          SurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              children: [
                for (final (i, item) in group.items.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: AppSpacing.xxl + AppSpacing.md),
                  SearchResultTile(
                    result: item,
                    query: query,
                    onTap: () => item.module.open(context, item),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapLg,
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final SearchModuleResult group;

  const _GroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final n = group.items.length;
    final capped = n >= SearchQueryBuilder.perModuleLimit;
    return SectionHeader(
      title: group.module.label,
      compact: true,
      trailing: Text(
        capped ? '${AppStrings.searchShowingFirst} $n' : '$n ${n == 1 ? AppStrings.searchResult : AppStrings.searchResults}',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

/// "Couldn't search: Books, Movies" — some modules failed, others didn't.
class _PartialFailureNotice extends StatelessWidget {
  final List<String> modules;
  final bool padded;

  const _PartialFailureNotice({required this.modules, this.padded = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notice = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: AppSpacing.md + AppSpacing.xs, color: AppColors.warning),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              '${AppStrings.searchPartialFailure} ${modules.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
    return padded
        ? Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0), child: notice)
        : notice;
  }
}
